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
}
