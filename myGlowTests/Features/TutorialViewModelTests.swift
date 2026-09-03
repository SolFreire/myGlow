//
//  TutorialViewModelTests.swift
//  myGlowTests
//

import Testing
@testable import myGlow

@Suite("Tutorial")
@MainActor
struct TutorialViewModelTests {
    private func montar(
        maleta: [String],
        etapas: [TutorialStep],
        suggester: SuggesterFalso = SuggesterFalso()
    ) -> (TutorialViewModel, SuggesterFalso, ProgressoEmMemoria) {
        let progresso = ProgressoEmMemoria()
        let vm = TutorialViewModel(
            roteiro: Fixture.roteiro(etapas: etapas),
            suggester: suggester,
            inventarioRepo: InventarioEmMemoria(ids: maleta),
            progressoRepo: progresso
        )
        return (vm, suggester, progresso)
    }

    /// O ponto mais importante: com a maleta completa o roteiro basta, e o app
    /// não paga 4-5 segundos de espera por uma dica que ninguém pediu.
    @Test("Não chama a IA quando a maleta tem tudo que a etapa precisa")
    func naoChamaIAComMaletaCompleta() async throws {
        let (vm, suggester, _) = montar(
            maleta: ["caneta-delineadora"],
            etapas: [Fixture.etapa(itensNecessarios: ["caneta-delineadora"])]
        )

        await vm.carregar()

        #expect(await suggester.chamadas == 0)
        #expect(vm.sugestao == .ociosa)
    }

    @Test("Chama a IA quando falta item e chega ao estado pronto")
    func chamaIAQuandoFalta() async throws {
        let (vm, suggester, _) = montar(
            maleta: ["lapis-preto"],
            etapas: [Fixture.etapa(itensNecessarios: ["caneta-delineadora"])]
        )

        await vm.carregar()

        #expect(await suggester.chamadas == 1)
        guard case .pronta = vm.sugestao else {
            Issue.record("Esperava sugestão pronta, veio \(vm.sugestao)")
            return
        }
    }

    @Test("Passa para a IA o inventário real, como snapshot Sendable")
    func passaOInventarioCerto() async throws {
        let (vm, suggester, _) = montar(
            maleta: ["lapis-preto", "gloss"],
            etapas: [Fixture.etapa(itensNecessarios: ["caneta-delineadora"])]
        )

        await vm.carregar()

        let enviado = await suggester.ultimoInventario.map(\.id).sorted()
        #expect(enviado == ["gloss", "lapis-preto"])
    }

    @Test("Erro da IA vira estado da tela, não explode")
    func erroViraEstado() async throws {
        let (vm, _, _) = montar(
            maleta: [],
            etapas: [Fixture.etapa(itensNecessarios: ["caneta-delineadora"])],
            suggester: SuggesterFalso(resultado: .failure(.guardrail))
        )

        await vm.carregar()

        guard case let .erro(mensagem) = vm.sugestao else {
            Issue.record("Esperava estado de erro, veio \(vm.sugestao)")
            return
        }
        #expect(!mensagem.isEmpty)
    }

    @Test("Avança fala a fala antes de trocar de etapa")
    func avancaFalaAFala() async throws {
        let etapa = Fixture.etapa(
            id: "a",
            itensNecessarios: [],
            falas: [Fixture.fala(.introducao, "Um"), Fixture.fala(.instrucaoPratica, "Dois")]
        )
        let (vm, _, progresso) = montar(
            maleta: [],
            etapas: [etapa, Fixture.etapa(id: "b", itensNecessarios: [], falas: [Fixture.fala(.fechamento, "Fim")])]
        )

        await vm.carregar()
        #expect(vm.falaAtual?.texto == "Um")

        await vm.avancar()
        #expect(vm.falaAtual?.texto == "Dois")
        #expect(progresso.etapasMarcadas.isEmpty, "A etapa só conclui depois da última fala")

        await vm.avancar()
        #expect(vm.etapaAtual?.id == "b")
        #expect(progresso.etapasMarcadas == ["a"])
    }

    @Test("A última etapa encerra o tutorial e registra a conclusão")
    func terminaNoFim() async throws {
        let (vm, _, progresso) = montar(
            maleta: [],
            etapas: [Fixture.etapa(id: "unica", tipo: .fechamento, itensNecessarios: [])]
        )

        await vm.carregar()
        await vm.avancar()

        #expect(vm.terminou)
        #expect(progresso.tutoriaisConcluidos == 1)
    }

    @Test("Lista os itens faltantes com o nome do catálogo")
    func nomeiaOsFaltantes() async throws {
        let (vm, _, _) = montar(
            maleta: [],
            etapas: [Fixture.etapa(itensNecessarios: ["clown", "pancake"])]
        )

        await vm.carregar()

        #expect(vm.itensFaltantes == ["Tinta clown", "Pancake"])
    }
}

/// Percorre a trilha real da Lucy, com o roteiro do bundle e o fallback de
/// regras estáticas — é o mesmo caminho que a tela faz, sem UI no meio.
@Suite("Tutorial com o roteiro real")
@MainActor
struct TutorialComRoteiroRealTests {
    @Test("Chegando na etapa Base sem o pancake, a sugestão fica pronta")
    func sugestaoNaEtapaBase() async throws {
        let roteiro = try RoteiroLoader.carregar(.gotica)
        let vm = TutorialViewModel(
            roteiro: roteiro,
            suggester: StaticRulesSuggester(roteiro: roteiro),
            inventarioRepo: InventarioEmMemoria(ids: ["clown"]),
            progressoRepo: ProgressoEmMemoria()
        )

        await vm.carregar()
        #expect(vm.etapaAtual?.id == "gotica-ola")

        // A abertura tem três falas: três avanços levam à etapa Base.
        let falasDaAbertura = try #require(vm.etapaAtual?.falas.count)
        for _ in 0..<falasDaAbertura {
            await vm.avancar()
        }

        #expect(vm.etapaAtual?.id == "gotica-base")
        #expect(vm.itensFaltantes == ["Pancake"])

        guard case let .pronta(sugestao) = vm.sugestao else {
            Issue.record("Faltando o pancake, a etapa Base deveria trazer uma sugestão. Veio \(vm.sugestao)")
            return
        }
        #expect(!sugestao.passos.isEmpty)
    }

    @Test("Com clown e pancake na maleta, a etapa Base não pede sugestão")
    func semSugestaoComMaletaCompleta() async throws {
        let roteiro = try RoteiroLoader.carregar(.gotica)
        let vm = TutorialViewModel(
            roteiro: roteiro,
            suggester: StaticRulesSuggester(roteiro: roteiro),
            inventarioRepo: InventarioEmMemoria(ids: ["clown", "pancake"]),
            progressoRepo: ProgressoEmMemoria()
        )

        await vm.carregar()
        for _ in 0..<(vm.etapaAtual?.falas.count ?? 0) {
            await vm.avancar()
        }

        #expect(vm.etapaAtual?.id == "gotica-base")
        #expect(vm.itensFaltantes.isEmpty)
        #expect(vm.sugestao == .ociosa)
    }
}

/// O roteiro já carrega, em cada fala, qual dos três balões o design usa —
/// foi por isso que os rótulos originais foram preservados no JSON.
@Suite("Estilo do balão a partir do roteiro")
@MainActor
struct EstiloDoBalaoTests {
    private func vm(etapas: [TutorialStep], subcultura: Subcultura = .gotica) -> TutorialViewModel {
        TutorialViewModel(
            roteiro: Fixture.roteiro(subcultura: subcultura, etapas: etapas),
            suggester: SuggesterFalso(),
            inventarioRepo: InventarioEmMemoria()
        )
    }

    @Test(
        "Cada tipo de fala escolhe o seu balão",
        arguments: [
            (Fala.Tipo.introducao, BalaoDeFala.Estilo.padrao),
            (.fechamentoIntro, .padrao),
            (.fechamento, .padrao),
            (.contexto, .padrao),
            (.instrucaoPratica, .passo),
            (.instrucaoPraticaTecnica, .passo),
            (.contextoHistorico, .contexto),
            (.contexto, .padrao),
            (.discussao, .contexto)
        ]
    )
    func mapeamento(_ tipo: Fala.Tipo, _ esperado: BalaoDeFala.Estilo) {
        #expect(tipo.estiloDoBalao == esperado)
    }

    @Test("Na fala normal, a aba traz o nome de quem fala")
    func rotuloPadrao() async {
        let modelo = vm(etapas: [Fixture.etapa(falas: [Fixture.fala(.introducao, "Oi")])])
        await modelo.carregar()

        #expect(modelo.estiloDaFala == .padrao)
        #expect(modelo.rotuloDaFala == "Lucy")
    }

    /// A abertura e o fechamento não contam: "Passo 1" é a primeira etapa de
    /// maquiagem de verdade.
    @Test("A aba do passo numera só as etapas práticas")
    func numeracaoDosPassos() async {
        let modelo = vm(etapas: [
            Fixture.etapa(id: "ola", tipo: .abertura, itensNecessarios: [], falas: [Fixture.fala(.introducao, "Oi")]),
            Fixture.etapa(id: "base", itensNecessarios: [], falas: [Fixture.fala(.instrucaoPratica, "Aplique")]),
            Fixture.etapa(id: "olhos", itensNecessarios: [], falas: [Fixture.fala(.instrucaoPratica, "Esfume")])
        ])
        await modelo.carregar()

        #expect(modelo.numeroDoPasso == nil, "A abertura não é um passo")

        await modelo.avancar()
        #expect(modelo.estiloDaFala == .passo)
        #expect(modelo.rotuloDaFala == "Passo 1")

        await modelo.avancar()
        #expect(modelo.rotuloDaFala == "Passo 2")
    }

    @Test("Sem título próprio, o balão de contexto usa o rótulo da subcultura")
    func rotuloDeContextoPadrao() async {
        let modelo = vm(etapas: [Fixture.etapa(falas: [Fixture.fala(.contextoHistorico, "Nos anos 70…")])])
        await modelo.carregar()

        #expect(modelo.estiloDaFala == .contexto)
        #expect(modelo.rotuloDaFala == "Sobre góticos")
    }

    @Test("Com título próprio, o balão de contexto usa o do roteiro")
    func rotuloDeContextoDoRoteiro() async {
        let fala = Fala(tipo: .contextoHistorico, texto: "O Bihaku…", titulo: "Sobre o Bihaku")
        let modelo = vm(etapas: [Fixture.etapa(falas: [fala])], subcultura: .gyaru)
        await modelo.carregar()

        #expect(modelo.rotuloDaFala == "Sobre o Bihaku")
    }

    @Test("Saltar para uma etapa leva à primeira fala dela")
    func saltoDeEtapa() async {
        let modelo = vm(etapas: [
            Fixture.etapa(id: "a", itensNecessarios: [], falas: [Fixture.fala(.introducao, "Um")]),
            Fixture.etapa(id: "b", itensNecessarios: [], falas: [Fixture.fala(.introducao, "Dois")])
        ])
        await modelo.carregar()

        await modelo.irParaEtapa(1)
        #expect(modelo.etapaAtual?.id == "b")

        await modelo.irParaEtapa(99)
        #expect(modelo.etapaAtual?.id == "b", "Índice fora da trilha não muda nada")
    }
}

/// A cena do tutorial: onde a personagem fica, quando o cenário desfoca, e o
/// voltar. Tudo derivado do roteiro, sem dado novo no JSON.
@Suite("Cena do tutorial")
@MainActor
struct CenaDoTutorialTests {
    private func vmDaLucy() throws -> TutorialViewModel {
        let roteiro = try RoteiroLoader.carregar(.gotica)
        return TutorialViewModel(
            roteiro: roteiro,
            suggester: StaticRulesSuggester(roteiro: roteiro),
            inventarioRepo: InventarioEmMemoria(ids: ["clown", "pancake"]),
            progressoRepo: ProgressoEmMemoria()
        )
    }

    /// Na fala normal o balão atravessa a base e a personagem fica atrás dele;
    /// no passo e no contexto o balão vai para a direita, então ela precisa sair
    /// de baixo dele.
    @Test("A posição da personagem acompanha o lugar do balão")
    func posicaoSegueOBalao() async throws {
        let vm = try vmDaLucy()
        await vm.carregar()

        #expect(vm.estiloDaFala == .padrao)
        #expect(vm.posicaoDaPersonagem == .aoCentro, "Atrás do balão que atravessa a tela")

        await vm.irParaEtapa(1)
        await vm.avancar()
        #expect(vm.estiloDaFala == .passo)
        #expect(vm.posicaoDaPersonagem == .aEsquerda, "O balão de passo ocupa a direita")

        await vm.avancar()
        #expect(vm.estiloDaFala == .contexto)
        #expect(vm.posicaoDaPersonagem == .aEsquerda, "O de contexto também")
    }

    /// O cenário desfoca na instrução e na curiosidade, e volta ao nítido na
    /// fala normal — é a mesma regra que escolhe o formato do balão.
    @Test("O foco acompanha o tipo da fala")
    func focoSegueOBalao() async throws {
        let vm = try vmDaLucy()
        await vm.carregar()

        #expect(vm.estiloDaFala == .padrao)
        #expect(!vm.cenaEmFoco, "A abertura mostra o salão nítido")

        await vm.irParaEtapa(1)
        await vm.avancar()
        #expect(vm.estiloDaFala == .passo)
        #expect(vm.cenaEmFoco, "A instrução técnica desfoca o cenário")

        await vm.avancar()
        #expect(vm.estiloDaFala == .contexto)
        #expect(vm.cenaEmFoco, "A discussão sobre o Afro-Goth também desfoca")
    }

    @Test("Na primeira fala não há como voltar")
    func semVoltarNoComeco() async throws {
        let vm = try vmDaLucy()
        await vm.carregar()

        #expect(!vm.podeVoltar)

        await vm.voltar()
        #expect(vm.etapaAtual?.id == "gotica-ola")
        #expect(vm.indiceFala == 0)
    }

    @Test("Voltar recua fala a fala e atravessa a fronteira de etapa")
    func voltarAtravessaEtapas() async throws {
        let vm = try vmDaLucy()
        await vm.carregar()

        await vm.irParaEtapa(1)
        #expect(vm.etapaAtual?.id == "gotica-base")
        #expect(vm.podeVoltar)

        await vm.voltar()
        #expect(vm.etapaAtual?.id == "gotica-ola", "Recua para a etapa anterior")
        #expect(vm.indiceFala == 2, "E cai na última fala dela, não na primeira")

        await vm.voltar()
        #expect(vm.indiceFala == 1)
    }

    /// Voltar para reler uma curiosidade não pode zerar o que já foi concluído.
    @Test("Voltar não desfaz progresso")
    func voltarPreservaProgresso() async throws {
        let roteiro = try RoteiroLoader.carregar(.gotica)
        let progresso = ProgressoEmMemoria()
        let vm = TutorialViewModel(
            roteiro: roteiro,
            suggester: StaticRulesSuggester(roteiro: roteiro),
            inventarioRepo: InventarioEmMemoria(ids: ["clown", "pancake"]),
            progressoRepo: progresso
        )
        await vm.carregar()

        for _ in 0..<3 { await vm.avancar() }
        #expect(progresso.etapasMarcadas == ["gotica-ola"])

        await vm.voltar()
        await vm.voltar()
        #expect(progresso.etapasMarcadas == ["gotica-ola"], "A etapa concluída continua concluída")
    }
}
