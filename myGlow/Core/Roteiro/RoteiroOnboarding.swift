//
//  RoteiroOnboarding.swift
//  myGlow
//

import Foundation


nonisolated struct RoteiroOnboarding: Codable, Hashable, Sendable {
    struct Personagem: Codable, Hashable, Sendable {
        let nome: String
        let papel: String
        let aparencia: String
        let personalidade: String
    }

    struct Passo: Codable, Hashable, Sendable {
        enum Tipo: String, Codable, Sendable {
            case fala
            case tela
        }

        enum Tela: String, Codable, Sendable {
            case cadastro
            case salao
        }

        let tipo: Tipo
        let falas: [String]?
        let tela: Tela?
    }

    let personagem: Personagem
    let passos: [Passo]
}
