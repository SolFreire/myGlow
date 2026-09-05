
//
//  Subcultura.swift
//  myGlow
//
//  Created by Soraia Freire Batista on 01/09/26.
//
import Foundation

nonisolated enum Subcultura: String, Codable, CaseIterable, Identifiable, Sendable {
    case gotica
    case gyaru
    case newRomantic

    var id: String { rawValue }

    var nome: String {
        switch self {
        case .gotica: "Gótica"
        case .gyaru: "Gyaru"
        case .newRomantic: "New Romantic"
        }
    }

    var personagem: String {
        switch self {
        case .gotica: "Lucy"
        case .gyaru: "Sana"
        case .newRomantic: "Cindy"
        }
    }

    var chamada: String {
        switch self {
        case .gotica: "Contraste, drama e um preto que não pede licença."
        case .gyaru: "Olhos enormes, brilho e atitude vinda de Shibuya."
        case .newRomantic: "Cor teatral e excesso elegante dos anos 80."
        }
    }
    
    var card: String {
        switch self {
        case .gotica: "card-lucy"
        case .gyaru: "card-sana"
        case .newRomantic: "card-cindy"
        }
    }
    
    var rotation: Double {
        switch self {
        case .gotica: -4.08
        case .gyaru: 5.03
        case .newRomantic: 2.2
        }
    }
    
    var x: Int {
        switch self {
        case .gotica: -250
        case .gyaru: 250
        case .newRomantic: -10
        }
    }
    var y: Int {
        switch self {
        case .gotica: 10
        case .gyaru: 0
        case .newRomantic: 40
        }
    }
}
