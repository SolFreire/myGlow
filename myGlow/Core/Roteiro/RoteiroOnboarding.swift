//
//  RoteiroOnboarding.swift
//  myGlow
//

import Foundation

/// O fluxo de primeiro uso conduzido pela Edna, a recepcionista.
///
/// Alterna falas e telas na mesma ordem do roteiro: ela recebe, manda cadastrar
/// a maleta, comenta o resultado, manda escolher a experiência e chama a
/// especialista.
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
