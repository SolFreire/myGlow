//
//  SuggesterComFallback.swift
//  myGlow
//

import Foundation

/// Tenta o modelo on-device e, se ele falhar por qualquer motivo, entrega a
/// sugestão das regras estáticas.
///
/// Existe por causa de um comportamento visto em execução: o
/// `SystemLanguageModel.availability` respondeu `.available` e a chamada seguinte
/// falhou mesmo assim. O levantamento técnico (§14) já alertava que o
/// availability não é confiável — há relato de ele dizer disponível com o modelo
/// ainda baixando, ou com o idioma da Siri divergindo do idioma do sistema.
///
/// Escolher a implementação uma vez, na fábrica, não basta: a decisão precisa
/// sobreviver a uma falha em tempo de execução. A pessoa não pode ficar sem dica
/// no meio do tutorial porque o sistema mentiu sobre a disponibilidade.
nonisolated struct SuggesterComFallback: TechniqueSuggesting {
    let principal: any TechniqueSuggesting
    let reserva: any TechniqueSuggesting

    func suggestTechnique(
        for step: TutorialStep,
        inventory: [ItemResumo]
    ) async throws -> TechniqueSuggestion {
        do {
            return try await principal.suggestTechnique(for: step, inventory: inventory)
        } catch {
            // Inclusive guardrail: se o conteúdo da estética gótica for recusado,
            // a trilha continua com o texto curado em vez de travar na etapa.
            return try await reserva.suggestTechnique(for: step, inventory: inventory)
        }
    }
}
