//
//  SuggesterComFallback.swift
//  myGlow
//

import Foundation


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

            return try await reserva.suggestTechnique(for: step, inventory: inventory)
        }
    }
}
