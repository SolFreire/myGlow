//
//  TechniqueSuggesterFactory.swift
//  myGlow
//

import Foundation
import FoundationModels


nonisolated enum TechniqueSuggesterFactory {
    static func make(
        roteiro: Roteiro,
        disponibilidade: SystemLanguageModel.Availability = SystemLanguageModel.default.availability
    ) -> any TechniqueSuggesting {
        let reserva = StaticRulesSuggester(roteiro: roteiro)

        switch disponibilidade {
        case .available:
            return SuggesterComFallback(
                principal: FoundationModelsSuggester(roteiro: roteiro),
                reserva: reserva
            )
        case .unavailable:
            return reserva
        }
    }

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
