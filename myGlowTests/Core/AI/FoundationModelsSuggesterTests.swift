//
//  FoundationModelsSuggesterTests.swift
//  myGlowTests
//

import Testing
@testable import myGlow

/// `mapear` é a única parte de `FoundationModelsSuggester` testável sem
/// dispositivo real — não chama a sessão, só decide o que fazer com o que ela
/// devolveria.
@Suite("Mapeamento da resposta do modelo")
struct FoundationModelsSuggesterTests {
    private func par(ausente: String, substituto: String) -> SubstituicoesCuradas.Par {
        SubstituicoesCuradas.Par(
            ausente: ausente,
            regra: SubstituicoesCuradas.Regra(substituto: substituto, comoFazer: "Como fazer de teste.")
        )
    }

    /// A checagem existia mas nada usava o resultado: uma dica citando produto
    /// fora da maleta chegava à tela do mesmo jeito. Isto é o que garante que
    /// `SuggesterComFallback` de fato entra em ação quando o modelo erra.
    @Test("Uma dica que cita produto fora da maleta é rejeitada")
    func rejeitaProdutoForaDaMaleta() {
        let gerada = FoundationModelsSuggester.DicaGerada(
            dica: "Sem Caneta delineadora? Passe um Blush antes para fixar melhor o traço."
        )

        #expect(throws: SuggestionError.respostaInvalida) {
            _ = try FoundationModelsSuggester.mapear(
                gerada,
                pares: [par(ausente: "caneta-delineadora", substituto: "lapis-preto")],
                maleta: Fixture.resumos("lapis-preto")
            )
        }
    }

    @Test("Uma dica que só cita o item ausente e produtos da maleta passa")
    func aceitaDicaLimpa() throws {
        let gerada = FoundationModelsSuggester.DicaGerada(
            dica: "Sem Caneta delineadora? Use o Lápis preto, pressionando mais firme no traço."
        )

        let sugestao = try FoundationModelsSuggester.mapear(
            gerada,
            pares: [par(ausente: "caneta-delineadora", substituto: "lapis-preto")],
            maleta: Fixture.resumos("lapis-preto")
        )

        #expect(sugestao.origem == .onDevice)
        #expect(sugestao.dica.contains("Lápis preto"))
    }

    /// A IA não decide mais qual produto usar — o par já vem pronto. Se algum
    /// dia essa restrição for removida sem querer, este teste é o primeiro a
    /// falhar: uma dica citando o próprio par esperado nunca é "fora da maleta".
    @Test("Citar o par esperado nunca conta como produto de fora")
    func citarOParEsperadoNaoEFlagrado() throws {
        let gerada = FoundationModelsSuggester.DicaGerada(
            dica: "Sem Blush? Use Batom: toque o dedo no produto e esfume nas maçãs do rosto."
        )

        let sugestao = try FoundationModelsSuggester.mapear(
            gerada,
            pares: [par(ausente: "blush", substituto: "batom")],
            maleta: Fixture.resumos("batom")
        )

        #expect(sugestao.dica.contains("Batom"))
    }

    /// Sem regra curada para o item ausente, a IA nem chega a ser chamada —
    /// `suggestTechnique` retorna antes de criar a sessão, então isto roda sem
    /// dispositivo real.
    @Test("Sem par curado, devolve o genérico sem chamar o modelo")
    func semParCuradoDevolveGenerico() async throws {
        // "gloss-brilhante" não existe na tabela — nenhuma regra se aplica.
        let etapa = Fixture.etapa(itensNecessarios: ["gloss-brilhante"])
        let suggester = FoundationModelsSuggester(roteiro: Fixture.roteiro())

        let sugestao = try await suggester.suggestTechnique(for: etapa, inventory: [])

        #expect(sugestao.dica == SubstituicoesCuradas.semSubstituto)
        #expect(sugestao.origem == .regrasEstaticas)
    }
}
