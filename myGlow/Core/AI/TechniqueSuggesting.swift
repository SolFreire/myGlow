//
//  TechniqueSuggesting.swift
//  myGlow
//

import Foundation

/// A fronteira entre o Tutorial e a IA.
///
/// A `TutorialViewModel` fala só com este protocolo: ela nunca sabe se a
/// sugestão veio do modelo on-device, das regras estáticas ou, mais para
/// frente, de um provedor de nuvem. Trocar a implementação não toca em UI.
protocol TechniqueSuggesting: Sendable {
    /// `inventory` chega como `[ItemResumo]`, e não como `[MakeupItem]`: o
    /// `@Model` do SwiftData não é `Sendable`, e o `Tool` do Foundation Models
    /// exige que seja. O snapshot é feito uma vez, na ViewModel.
    func suggestTechnique(
        for step: TutorialStep,
        inventory: [ItemResumo]
    ) async throws -> TechniqueSuggestion
}

nonisolated enum SuggestionError: Error, LocalizedError, Equatable {
    /// O guardrail de conteúdo da Apple recusou o pedido. Não pode ser desativado
    /// (§6 do documento de arquitetura), então é tratado como estado da tela.
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
            // O detalhe técnico fica guardado no case, para log e diagnóstico —
            // quem está aprendendo maquiagem não deve ler erro de framework.
            "Não consegui montar essa dica agora. Seguimos com o passo do roteiro?"
        }
    }
}

/// Checagem determinística: quais produtos do catálogo aparecem no texto gerado
/// **sem** estarem na maleta.
///
/// A PoC mostrou que pedir educadamente para o modelo usar só o inventário não
/// basta — ele cita primer e pó que ninguém tem. Isto roda depois da geração,
/// sobre o texto final, independente de qual implementação o produziu.
///
/// A busca é por palavra inteira, e não por trecho: há nomes curtos no catálogo
/// ("Pó", "Gloss"), e um trecho solto acusaria "Pó" dentro de "pós-punk" — que
/// é justamente uma palavra do roteiro da Lucy.
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
