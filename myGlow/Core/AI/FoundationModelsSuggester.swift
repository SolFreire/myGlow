//
//  FoundationModelsSuggester.swift
//  myGlow
//

import Foundation
import FoundationModels

/// Sugestão de técnica gerada on-device pelo Foundation Models.
///
/// Exige iOS 26 num aparelho com Apple Intelligence — como o mínimo do projeto
/// já é iOS 26, não há `#available` aqui; quem decide se esta implementação pode
/// ser usada é a `TechniqueSuggesterFactory`.
nonisolated struct FoundationModelsSuggester: TechniqueSuggesting {
    let roteiro: Roteiro

    func suggestTechnique(
        for step: TutorialStep,
        inventory: [ItemResumo]
    ) async throws -> TechniqueSuggestion {
        let maleta = inventory
        let faltantes = step
            .itensFaltantes(naMaleta: Set(maleta.map(\.id)))
            .map(CatalogoMaquiagem.nome(paraID:))

        let sessao = LanguageModelSession(
            tools: [MaletaTool(itens: maleta)],
            instructions: Self.instructions(roteiro: roteiro)
        )

        do {
            let resposta = try await sessao.respond(
                to: Self.prompt(etapa: step, faltantes: faltantes),
                generating: SugestaoGerada.self
            )
            return Self.mapear(resposta.content, maleta: maleta)
        } catch let erro as LanguageModelSession.GenerationError {
            throw Self.traduzir(erro)
        } catch {
            throw SuggestionError.falha(error.localizedDescription)
        }
    }

    // MARK: - Instructions

    /// Contexto fixo da sessão: quem é a personagem e o que a subcultura é.
    ///
    /// A PoC (§14 do levantamento) mostrou que o nome da subcultura sozinho não
    /// basta — "new romantic" cru volta "maquiagem romântica" genérica. Por isso
    /// o briefing entra aqui, uma vez, e não é reforçado a cada chamada.
    static func instructions(roteiro: Roteiro) -> String {
        """
        Você é \(roteiro.personagem.nome), maquiadora especialista em \(roteiro.subcultura.nome), \
        guiando uma pessoa passo a passo no salão myGlow.

        SOBRE A SUBCULTURA
        \(roteiro.briefing)

        SUA VOZ
        \(roteiro.personagem.personalidade)

        REGRAS OBRIGATÓRIAS
        1. Use SOMENTE produtos que a pessoa tem na maleta. Consulte a ferramenta \
        "consultarMaleta" para saber quais são. Nunca cite um produto que não esteja lá — \
        nem primer, nem pó, nem pincel específico, nem nada "que geralmente se usa".
        2. A maleta é uma lista de opções disponíveis, NÃO uma lista de itens a usar por \
        completo. Se um item não faz sentido para esta etapa ou para esta estética, coloque-o \
        em "itensNaoUtilizados" com o motivo, em vez de forçá-lo na sugestão.
        3. Responda em português do Brasil, na primeira pessoa, na sua voz.
        4. A curiosidade deve ser histórica ou cultural sobre a subcultura, curta, e ligada \
        ao que está sendo feito na etapa.
        """
    }

    static func prompt(etapa: TutorialStep, faltantes: [String]) -> String {
        let objetivo = etapa.falas
            .filter { $0.tipo == .instrucaoPratica || $0.tipo == .instrucaoPraticaTecnica }
            .map(\.texto)
            .joined(separator: " ")

        let ausentes = faltantes.isEmpty
            ? "Nenhum item essencial está faltando."
            : "A pessoa NÃO tem: \(faltantes.joined(separator: ", ")). Explique como recriar o efeito com o que ela tem."

        return """
        Etapa atual: \(etapa.titulo).
        O que essa etapa faz: \(objetivo)
        \(ausentes)
        """
    }

    // MARK: - Saída estruturada

    @Generable
    struct SugestaoGerada {
        @Guide(description: "Passo a passo em português do Brasil, na voz da personagem, usando apenas produtos da maleta.")
        var passos: [String]

        @Guide(description: "Como recriar o efeito de cada produto que falta usando um produto que a pessoa tem.")
        var substituicoes: [SubstituicaoGerada]

        @Guide(description: "Produtos da maleta que você decidiu NÃO usar nesta etapa, cada um com o motivo.")
        var itensNaoUtilizados: [ItemNaoUtilizadoGerado]

        @Guide(description: "Uma curiosidade histórica ou cultural curta sobre a subcultura, ligada a esta etapa.")
        var curiosidade: String
    }

    @Generable
    struct SubstituicaoGerada {
        @Guide(description: "O produto que falta na maleta.")
        var itemAusente: String

        @Guide(description: "O produto da maleta que vai fazer o papel dele.")
        var itemUsado: String

        @Guide(description: "Como fazer, na prática.")
        var comoFazer: String
    }

    @Generable
    struct ItemNaoUtilizadoGerado {
        @Guide(description: "O produto da maleta que ficou de fora.")
        var item: String

        @Guide(description: "Por que ele não entra nesta etapa ou nesta estética.")
        var motivo: String
    }

    // MARK: - Tool

    /// Deixa o modelo consultar a maleta durante a geração, em vez de a gente
    /// injetar o inventário inteiro no prompt a cada chamada.
    struct MaletaTool: Tool {
        let name = "consultarMaleta"
        let description = "Lista os produtos de maquiagem que a pessoa tem disponíveis, opcionalmente filtrando por categoria."
        let itens: [ItemResumo]

        @Generable
        struct Arguments {
            @Guide(description: "Categoria para filtrar, como 'batom' ou 'sombra'. Deixe vazio para listar tudo.")
            var categoria: String
        }

        func call(arguments: Arguments) async throws -> String {
            let filtro = arguments.categoria.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let selecionados = filtro.isEmpty
                ? itens
                : itens.filter { $0.categoria.lowercased().contains(filtro) || $0.nome.lowercased().contains(filtro) }

            guard !selecionados.isEmpty else {
                return "A pessoa não tem nenhum produto dessa categoria na maleta."
            }
            return selecionados.map { "\($0.nome) (\($0.categoria))" }.joined(separator: "; ")
        }
    }

    // MARK: - Mapeamento e erros

    static func mapear(_ gerada: SugestaoGerada, maleta: [ItemResumo]) -> TechniqueSuggestion {
        let substituicoes = gerada.substituicoes.map {
            TechniqueSuggestion.Substituicao(
                itemAusente: $0.itemAusente,
                itemUsado: $0.itemUsado,
                comoFazer: $0.comoFazer
            )
        }
        let naoUtilizados = gerada.itensNaoUtilizados.map {
            TechniqueSuggestion.ItemNaoUtilizado(item: $0.item, motivo: $0.motivo)
        }

        // Rede de segurança: mesmo com as regras nas instructions e o campo de
        // itens não utilizados, a PoC viu o modelo citar produto fora da lista.
        // A conferência é feita no código, sobre o texto final.
        let textos = gerada.passos + substituicoes.map(\.comoFazer) + [gerada.curiosidade]

        return TechniqueSuggestion(
            passos: gerada.passos,
            substituicoes: substituicoes,
            itensNaoUtilizados: naoUtilizados,
            curiosidade: gerada.curiosidade,
            itensForaDaMaleta: ChecagemDeInventario.itensForaDaMaleta(emTextos: textos, maleta: maleta),
            origem: .onDevice
        )
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
