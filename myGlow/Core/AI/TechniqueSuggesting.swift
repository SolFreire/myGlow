//
//  TechniqueSuggesting.swift
//  myGlow
//

import Foundation


protocol TechniqueSuggesting: Sendable {

    func suggestTechnique(
        for step: TutorialStep,
        inventory: [ItemResumo]
    ) async throws -> TechniqueSuggestion
}

nonisolated enum SuggestionError: Error, LocalizedError, Equatable {

    case guardrail
    case modeloIndisponivel(String)
    case respostaInvalida
    case falha(String)

    var errorDescription: String? {
        switch self {
        case .guardrail:
            "Não consegui montar essa dica agora. Vamos seguir com o passo do roteiro?"
        case let .modeloIndisponivel(motivo):
            "A sugestão personalizada não está disponível neste aparelho (\(motivo))."
        case .respostaInvalida:
            "A resposta veio incompleta. Tenta de novo?"
        case .falha:

            "Não consegui montar essa dica agora. Seguimos com o passo do roteiro?"
        }
    }
}


nonisolated enum ChecagemDeInventario {
    static func itensForaDaMaleta(
        emTextos textos: [String],
        maleta: [ItemResumo],
        catalogo: [ItemCatalogo] = CatalogoMaquiagem.todos
    ) -> [String] {
        let texto = textos.joined(separator: " ").folding(
            options: [.diacriticInsensitive, .caseInsensitive],
            locale: Locale(identifier: "pt_BR")
        )
        let idsNaMaleta = Set(maleta.map(\.id))

        return catalogo
            .filter { !idsNaMaleta.contains($0.id) }
            .filter { item in
                let nome = item.nome.folding(
                    options: [.diacriticInsensitive, .caseInsensitive],
                    locale: Locale(identifier: "pt_BR")
                )
                return texto.range(of: "\\b\(NSRegularExpression.escapedPattern(for: nome))\\b",
                                   options: .regularExpression) != nil
            }
            .map(\.nome)
    }
}
