//
//  FoundationModelsSuggester.swift
//  myGlow
//

import Foundation
import FoundationModels


nonisolated struct FoundationModelsSuggester: TechniqueSuggesting {
    let roteiro: Roteiro

    func suggestTechnique(
        for step: TutorialStep,
        inventory: [ItemResumo]
    ) async throws -> TechniqueSuggestion {
        let idsNaMaleta = Set(inventory.map(\.id))
        let faltantes = step.itensFaltantes(naMaleta: idsNaMaleta)
        let aplicaveis = SubstituicoesCuradas.aplicaveis(faltantes: faltantes, idsNaMaleta: idsNaMaleta)


        guard !aplicaveis.isEmpty else {
            return TechniqueSuggestion(dica: SubstituicoesCuradas.semSubstituto, origem: .regrasEstaticas)
        }

        let sessao = LanguageModelSession(instructions: Self.instructions(roteiro: roteiro))

        do {
            let dicaGerada: String
            if Self.respondendoEmIngles {
                let resposta = try await sessao.respond(
                    to: Self.prompt(pares: aplicaveis, etapa: step),
                    generating: DicaGeradaEmIngles.self
                )
                dicaGerada = resposta.content.dica
            } else {
                let resposta = try await sessao.respond(
                    to: Self.prompt(pares: aplicaveis, etapa: step),
                    generating: DicaGerada.self
                )
                dicaGerada = resposta.content.dica
            }
            return try Self.mapear(dicaGerada, pares: aplicaveis, maleta: inventory)
        } catch let erro as SuggestionError {
            throw erro
        } catch let erro as LanguageModelSession.GenerationError {
            throw Self.traduzir(erro)
        } catch {
            throw SuggestionError.falha(error.localizedDescription)
        }
    }



    private static var respondendoEmIngles: Bool {
        Bundle.main.preferredLocalizations.first?.hasPrefix("en") ?? false
    }

    static func instructions(roteiro: Roteiro) -> String {
        guard respondendoEmIngles else {
            return """
            Você é \(roteiro.personagem.nome), maquiadora especialista em \(roteiro.subcultura.nome), \
            guiando uma pessoa passo a passo no salão myGlow.

            SUA VOZ
            \(roteiro.personagem.personalidade)

            REGRAS OBRIGATÓRIAS
            1. A troca de produto já foi decidida você só explica COMO fazer.\
            Cite os produtos exatamente como foram nomeados no pedido, sem inventar \
            cor, acabamento ou variante que não foi mencionada.\
            2. Responda em português do Brasil, na primeira pessoa, na sua voz.
            3. Uma dica curta e objetiva — no máximo três linhas ao todo, sem lista, sem introdução.
            """
        }

        return """
        You are \(roteiro.personagem.nome), a makeup artist specializing in \(roteiro.subcultura.nome), \
        guiding someone step by step through the myGlow salon.

        YOUR VOICE
        \(roteiro.personagem.personalidade)

        MANDATORY RULES
        1. The product swap has already been decided — you only explain HOW to do it. \
        Refer to the products exactly as they were named in the request, without inventing \
        a color, finish, or variant that wasn't mentioned.
        2. Respond in English, in the first person, in your voice.
        3. One short, to-the-point tip — at most three lines total, no lists, no introduction.
        """
    }

    static func prompt(pares: [SubstituicoesCuradas.Par], etapa: TutorialStep) -> String {
        guard respondendoEmIngles else {
            let linhas = pares.map { par -> String in
                let categAusente = CatalogoMaquiagem.item(id: par.ausente)?.categoria ?? .base
                let categSubstituto = CatalogoMaquiagem.item(id: par.regra.substituto)?.categoria ?? .base
                let regiao = SubstituicoesCuradas.regiao(da: categAusente)

                return """
                - Sem \(CatalogoMaquiagem.nome(paraID: par.ausente)) (região: \(regiao)). \
                \(SubstituicoesCuradas.fatoTecnico(da: categAusente))
                  Use \(CatalogoMaquiagem.nome(paraID: par.regra.substituto)) no lugar. \
                \(SubstituicoesCuradas.fatoTecnico(da: categSubstituto))
                """
            }.joined(separator: "\n")

            return """
            Etapa atual: \(etapa.titulo).
            Trocas já decididas para esta etapa, com os fatos que valem pra cada produto:
            \(linhas)
            Explique como fazer cada troca, na prática — usando só os fatos acima, sem \
            inventar característica de produto que não foi dita, se atente onde do rosto a dica está sendo aplicada.
            """
        }

        let linhas = pares.map { par -> String in
            let categAusente = CatalogoMaquiagem.item(id: par.ausente)?.categoria ?? .base
            let categSubstituto = CatalogoMaquiagem.item(id: par.regra.substituto)?.categoria ?? .base
            let regiao = SubstituicoesCuradas.regiao(da: categAusente)

            return """
            - Missing \(CatalogoMaquiagem.nome(paraID: par.ausente)) (area: \(regiao)). \
            \(SubstituicoesCuradas.fatoTecnico(da: categAusente))
              Use \(CatalogoMaquiagem.nome(paraID: par.regra.substituto)) instead. \
            \(SubstituicoesCuradas.fatoTecnico(da: categSubstituto))
            """
        }.joined(separator: "\n")

        return """
        Current step: \(etapa.titulo).
        Swaps already decided for this step, with the facts that apply to each product:
        \(linhas)
        Explain how to make each swap, in practice — using only the facts above, without \
        inventing a product characteristic that wasn't stated, and pay attention to where on the face the tip is being applied.
        """
    }


    // @Guide(description:) precisa ser um literal — não dá pra montar em runtime
    // a partir do idioma. Por isso existem dois @Generable quase idênticos, um
    // por idioma: o texto do @Guide é a única instrução que o modelo on-device
    // vê diretamente atrelada ao campo gerado, então se ficasse só em português
    // ele podia "puxar" a resposta pro português mesmo com o resto do prompt em
    // inglês — daí a necessidade de uma versão traduzida também aqui, e não só
    // em instructions()/prompt().
    @Generable
    struct DicaGerada {
        @Guide(description: """
        Uma explicação curta e objetiva de como fazer a(s) troca(s) já decidida(s). Direto \
        ao ponto, sem lista e sem saudação — precisa caber em até três linhas de um balão de \
        fala (por volta de 200 caracteres).
        """)
        var dica: String
    }

    @Generable
    struct DicaGeradaEmIngles {
        @Guide(description: """
        A short, to-the-point explanation of how to make the already-decided swap(s). \
        Straight to the point, no list, no greeting — must fit within three lines of a \
        speech bubble (around 200 characters).
        """)
        var dica: String
    }

    static func mapear(
        _ dicaGerada: String,
        pares: [SubstituicoesCuradas.Par],
        maleta: [ItemResumo]
    ) throws -> TechniqueSuggestion {
        let dica = LimiteDaDica.aplicar(dicaGerada)


        let esperados = Set(pares.flatMap { [$0.ausente, $0.regra.substituto] })
        let catalogoParaChecagem = CatalogoMaquiagem.todos.filter { !esperados.contains($0.id) }
        let foraDaMaleta = ChecagemDeInventario.itensForaDaMaleta(
            emTextos: [dica],
            maleta: maleta,
            catalogo: catalogoParaChecagem
        )

        guard foraDaMaleta.isEmpty else {
            throw SuggestionError.respostaInvalida
        }

        return TechniqueSuggestion(dica: dica, origem: .onDevice)
    }

    static func traduzir(_ erro: LanguageModelSession.GenerationError) -> SuggestionError {
        switch erro {
        case .guardrailViolation, .refusal:
            .guardrail
        case .decodingFailure:
            .respostaInvalida
        case let .assetsUnavailable(contexto):
            .modeloIndisponivel(contexto.debugDescription)
        default:
            .falha(erro.localizedDescription)
        }
    }
}
