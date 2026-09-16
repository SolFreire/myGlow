//
//  ItemCatalogo.swift
//  myGlow
//

import Foundation


nonisolated struct ItemCatalogo: Identifiable, Hashable, Sendable {
    let id: String
    let nome: String
    let categoria: CategoriaItem
    /// Nome do asset ilustrado no `Assets.xcassets`. A arte não contém
    /// texto — o nome do produto é desenhado por `CartaoDeItem` a partir
    /// de `nome`, já localizado.
    let asset: String
}


nonisolated enum CatalogoMaquiagem {
    static let todos: [ItemCatalogo] = rosto + olhos + boca

    static let rosto: [ItemCatalogo] = [
        item("base", String(localized: "Base"), .base),
        item("corretivo", String(localized: "Corretivo"), .corretivo),
        item("po", String(localized: "Pó"), .po),
        item("blush", String(localized: "Blush"), .blush),
        item("contorno", String(localized: "Contorno"), .contorno),
        item("iluminador", String(localized: "Iluminador"), .iluminador),
        item("clown", String(localized: "Tinta clown"), .clown),
        item("pancake", String(localized: "Pancake"), .pancake)
    ]

    static let olhos: [ItemCatalogo] = [
        item("sombra-branca", String(localized: "Sombra branca"), .sombra),
        item("sombra-preta", String(localized: "Sombra preta"), .sombra),
        item("sombra-laranja", String(localized: "Sombra laranja"), .sombra),
        item("sombra-azul", String(localized: "Sombra azul"), .sombra),
        item("sombra-roxa", String(localized: "Sombra roxa"), .sombra),
        item("sombra-magenta", String(localized: "Sombra magenta"), .sombra),
        item("sombra-amarela", String(localized: "Sombra amarela"), .sombra),
        item("sombra-verde", String(localized: "Sombra verde"), .sombra),
        item("caneta-delineadora", String(localized: "Caneta delineadora"), .delineadorLiquido),
        item("lapis-preto", String(localized: "Lápis preto"), .lapisOlho),
        item("lapis-branco", String(localized: "Lápis branco"), .lapisOlhoBranco),
        item("mascara-cilios", String(localized: "Máscara de cílios"), .mascara),
        item("cilios-posticos", String(localized: "Cílios postiços"), .ciliosPosticos),
    ]

    static let boca: [ItemCatalogo] = [
        item("batom", String(localized: "Batom"), .batom),
        item("gloss", String(localized: "Gloss"), .gloss),
        item("lapis-labial", String(localized: "Lápis labial"), .lapisLabial)
    ]

    static func item(id: String) -> ItemCatalogo? {
        todos.first { $0.id == id }
    }

    static func itens(ids: [String]) -> [ItemCatalogo] {
        ids.compactMap(item(id:))
    }


    static func nome(paraID id: String) -> String {
        item(id: id)?.nome ?? id
    }

    private static func item(
        _ id: String,
        _ nome: String,
        _ categoria: CategoriaItem
    ) -> ItemCatalogo {
        ItemCatalogo(id: id, nome: nome, categoria: categoria, asset: "item-\(id)")
    }
}
