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
            let resposta = try await sessao.respond(
                to: Self.prompt(pares: aplicaveis, etapa: step),
                generating: DicaGerada.self
            )
            return try Self.mapear(resposta.content, pares: aplicaveis, maleta: inventory)
        } catch let erro as SuggestionError {
            throw erro
        } catch let erro as LanguageModelSession.GenerationError {
            throw Self.traduzir(erro)
        } catch {
            throw SuggestionError.falha(error.localizedDescription)
        }
    }


    static func instructions(roteiro: Roteiro) -> String {
        """
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

    static func prompt(pares: [SubstituicoesCuradas.Par], etapa: TutorialStep) -> String {
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


    @Generable
    struct DicaGerada {
        @Guide(description: """
        Uma explicação curta e objetiva de como fazer a(s) troca(s) já decidida(s). Direto \
        ao ponto, sem lista e sem saudação — precisa caber em até três linhas de um balão de \
        fala (por volta de 200 caracteres).
        """)
        var dica: String
    }

    static func mapear(
        _ gerada: DicaGerada,
        pares: [SubstituicoesCuradas.Par],
        maleta: [ItemResumo]
    ) throws -> TechniqueSuggestion {
        let dica = LimiteDaDica.aplicar(gerada.dica)


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
