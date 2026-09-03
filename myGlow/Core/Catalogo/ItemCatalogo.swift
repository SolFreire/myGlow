//
//  ItemCatalogo.swift
//  myGlow
//

import Foundation


nonisolated struct ItemCatalogo: Identifiable, Hashable, Sendable {
    let id: String
    let nome: String
    let categoria: CategoriaItem
    /// Nome do asset ilustrado no `Assets.xcassets`. O nome do produto vem
    /// desenhado dentro da arte.
    let asset: String
}


nonisolated enum CatalogoMaquiagem {
    static let todos: [ItemCatalogo] = rosto + olhos + boca

    static let rosto: [ItemCatalogo] = [
        item("base", "Base", .base),
        item("corretivo", "Corretivo", .corretivo),
        item("po", "Pó", .po),
        item("blush", "Blush", .blush),
        item("contorno", "Contorno", .contorno),
        item("iluminador", "Iluminador", .iluminador),
        item("clown", "Tinta clown", .clown),
        item("pancake", "Pancake", .pancake)
    ]

    static let olhos: [ItemCatalogo] = [
        item("sombra-branca", "Sombra branca", .sombra),
        item("sombra-preta", "Sombra preta", .sombra),
        item("sombra-laranja", "Sombra laranja", .sombra),
        item("sombra-azul", "Sombra azul", .sombra),
        item("sombra-roxa", "Sombra roxa", .sombra),
        item("sombra-magenta", "Sombra magenta", .sombra),
        item("sombra-amarela", "Sombra amarela", .sombra),
        item("sombra-verde", "Sombra verde", .sombra),
        item("caneta-delineadora", "Caneta delineadora", .delineadorLiquido),
        item("lapis-preto", "Lápis preto", .lapisOlho),
        item("lapis-branco", "Lápis branco", .lapisOlhoBranco),
        item("mascara-cilios", "Máscara de cílios", .mascara),
        item("cilios-posticos", "Cílios postiços", .ciliosPosticos),
    ]

    static let boca: [ItemCatalogo] = [
        item("batom", "Batom", .batom),
        item("gloss", "Gloss", .gloss),
        item("lapis-labial", "Lápis labial", .lapisLabial)
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
