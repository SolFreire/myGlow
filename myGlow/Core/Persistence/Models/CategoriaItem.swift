//
//  CategoriaItem.swift
//  myGlow
//

import Foundation

/// Categoria de um item de maquiagem.
///
/// Vem sempre do catálogo curado (`CatalogoMaquiagem`), nunca de texto digitado
/// pela pessoa — por isso não existe validação de texto livre em lugar nenhum
/// do fluxo de cadastro.
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
        case .base: "Base"
        case .corretivo: "Corretivo"
        case .po: "Pó"
        case .blush: "Blush"
        case .contorno: "Contorno"
        case .iluminador: "Iluminador"
        case .sombra: "Sombra"
        case .delineadorLiquido: "Delineador líquido"
        case .lapisOlho: "Lápis de olho"
        case .lapisOlhoBranco: "Lápis de olho branco"
        case .mascara: "Máscara de cílios"
        case .sobrancelha: "Sobrancelha"
        case .batom: "Batom"
        case .gloss: "Gloss"
        case .lapisLabial: "Lápis labial"
        case .clown: "Clown"
        case .pancake: "Pancake"
        case .ciliosPosticos: "Cílios postiços"
        }
    }
}
