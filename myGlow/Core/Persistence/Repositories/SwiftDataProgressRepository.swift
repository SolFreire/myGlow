//
//  SwiftDataProgressRepository.swift
//  myGlow
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataProgressRepository: ProgressRepository {
    private let contexto: ModelContext

    init(contexto: ModelContext) {
        self.contexto = contexto
    }

    func progresso(de subcultura: Subcultura) async throws -> UserProgress {
        if let existente = try buscar(subcultura) { return existente }

        let novo = UserProgress(subcultura: subcultura)
        contexto.insert(novo)
        try contexto.save()
        return novo
    }

    func marcarEtapaConcluida(_ etapaID: String, em subcultura: Subcultura) async throws {
        let progresso = try await progresso(de: subcultura)
        guard !progresso.etapasConcluidas.contains(etapaID) else { return }

        progresso.etapasConcluidas.append(etapaID)
        progresso.atualizadoEm = .now
        try contexto.save()
    }

    func marcarTutorialConcluido(_ subcultura: Subcultura) async throws {
        let progresso = try await progresso(de: subcultura)
        progresso.tutoriaisConcluidos += 1
        progresso.atualizadoEm = .now
        try contexto.save()
    }

    /// Filtra em memória de propósito: `subcultura` é um enum `Codable` e não
    /// entra num `#Predicate`. São no máximo três registros.
    private func buscar(_ subcultura: Subcultura) throws -> UserProgress? {
        try contexto
            .fetch(FetchDescriptor<UserProgress>())
            .first { $0.subcultura == subcultura }
    }
}
