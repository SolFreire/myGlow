//
//  Roteiro.swift
//  myGlow
//

import Foundation

nonisolated struct Fala: Codable, Hashable, Identifiable, Sendable {
    enum Tipo: String, Codable, Sendable {
        case introducao
        case contextoHistorico
        case contexto
        case fechamentoIntro
        case instrucaoPratica
        case instrucaoPraticaTecnica
        case discussao
        case fechamento

        var rotulo: String {
            switch self {
            case .introducao: "Introdução"
            case .contextoHistorico: "Contexto histórico"
            case .contexto: "Contexto"
            case .fechamentoIntro: "Fechamento da intro"
            case .instrucaoPratica: "Instrução prática"
            case .instrucaoPraticaTecnica: "Instrução prática de técnica"
            case .discussao: "Discussão"
            case .fechamento: "Fechamento"
            }
        }
    }

    let tipo: Tipo
    let texto: String
    var titulo: String?

    var id: String { "\(tipo.rawValue)-\(texto.prefix(24))" }
}


nonisolated struct TutorialStep: Codable, Hashable, Identifiable, Sendable {
    enum Tipo: String, Codable, Sendable {
        case abertura
        case passo
        case fechamento
    }

    let id: String
    let titulo: String
    let tipo: Tipo
    let itensNecessarios: [String]
    let ilustracoes: [String]
    let falas: [Fala]

    let nota: String?

    func itensFaltantes(naMaleta maleta: Set<String>) -> [String] {
        itensNecessarios.filter { !maleta.contains($0) }
    }
}


nonisolated struct RoteiroPersonagem: Codable, Hashable, Sendable {
    let nome: String
    let aparencia: String
    let personalidade: String
    let produtos: [String]
}


nonisolated struct Roteiro: Codable, Hashable, Sendable {
    let subcultura: Subcultura
    let briefing: String
    let personagem: RoteiroPersonagem
    let etapas: [TutorialStep]

    func etapa(id: String) -> TutorialStep? {
        etapas.first { $0.id == id }
    }
}
