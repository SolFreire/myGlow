//
//  CategoriaItem.swift
//  myGlow
//

import Foundation


nonisolated enum CategoriaItem: String, Codable, CaseIterable, Sendable {
    case base
    case corretivo
    case po
    case blush
    case contorno
    case iluminador
    case sombra
    case delineadorLiquido
    case lapisOlho
    case lapisOlhoBranco
    case mascara
    case sobrancelha
    case batom
    case gloss
    case lapisLabial
    case clown
    case pancake
    case ciliosPosticos

    var nome: String {
        switch self {
        case .base: String(localized: "Base")
        case .corretivo: String(localized: "Corretivo")
        case .po: String(localized: "Pó")
        case .blush: String(localized: "Blush")
        case .contorno: String(localized: "Contorno")
        case .iluminador: String(localized: "Iluminador")
        case .sombra: String(localized: "Sombra")
        case .delineadorLiquido: String(localized: "Delineador líquido")
        case .lapisOlho: String(localized: "Lápis de olho")
        case .lapisOlhoBranco: String(localized: "Lápis de olho branco")
        case .mascara: String(localized: "Máscara de cílios")
        case .sobrancelha: String(localized: "Sobrancelha")
        case .batom: String(localized: "Batom")
        case .gloss: String(localized: "Gloss")
        case .lapisLabial: String(localized: "Lápis labial")
        case .clown: String(localized: "Clown")
        case .pancake: String(localized: "Pancake")
        case .ciliosPosticos: String(localized: "Cílios postiços")
        }
    }
}
