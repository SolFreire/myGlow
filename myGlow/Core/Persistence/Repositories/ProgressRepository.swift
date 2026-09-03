//
//  ProgressRepository.swift
//  myGlow
//

import Foundation

protocol ProgressRepository: Sendable {
    func progresso(de subcultura: Subcultura) async throws -> UserProgress
    func marcarEtapaConcluida(_ etapaID: String, em subcultura: Subcultura) async throws
    func marcarTutorialConcluido(_ subcultura: Subcultura) async throws
}
