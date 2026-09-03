//
//  TechniqueSuggesterFactory.swift
//  myGlow
//

import Foundation
import FoundationModels

/// Escolhe qual implementação de `TechniqueSuggesting` usar.
///
/// A disponibilidade entra por parâmetro em vez de ser lida direto do
/// `SystemLanguageModel`: é o que permite testar a decisão sem um iPhone 15 Pro
/// à mão. O default cobre o uso real.
nonisolated enum TechniqueSuggesterFactory {
    static func make(
        roteiro: Roteiro,
        disponibilidade: SystemLanguageModel.Availability = SystemLanguageModel.default.availability
    ) -> any TechniqueSuggesting {
        let reserva = StaticRulesSuggester(roteiro: roteiro)

        switch disponibilidade {
        case .available:
            // Mesmo com o sistema dizendo que o modelo está disponível, a chamada
            // pode falhar — já aconteceu. As regras estáticas ficam atrás como rede.
            return SuggesterComFallback(
                principal: FoundationModelsSuggester(roteiro: roteiro),
                reserva: reserva
            )
        case .unavailable:
            return reserva
        }
    }

    /// Texto de diagnóstico. A PoC pede exibir o motivo bruto do `.unavailable`,
    /// porque já houve caso de o availability mentir quando o idioma da Siri
    /// diverge do idioma do sistema.
    static func diagnostico(
        _ disponibilidade: SystemLanguageModel.Availability = SystemLanguageModel.default.availability
    ) -> String {
        switch disponibilidade {
        case .available:
            "Foundation Models disponível — sugestões geradas on-device."
        case let .unavailable(motivo):
            switch motivo {
            case .deviceNotEligible:
                "Aparelho não compatível com Apple Intelligence — usando regras estáticas."
            case .appleIntelligenceNotEnabled:
                "Apple Intelligence desligada nos Ajustes — usando regras estáticas."
            case .modelNotReady:
                "Modelo ainda baixando — usando regras estáticas."
            @unknown default:
                "Foundation Models indisponível (motivo desconhecido) — usando regras estáticas."
            }
        }
    }
}
