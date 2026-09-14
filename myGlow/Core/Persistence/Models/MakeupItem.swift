//
//  MakeupItem.swift
//  myGlow
//

import Foundation
import SwiftData


@Model
final class MakeupItem {
    var catalogoID: String = ""
    var nome: String = ""
    var categoria: CategoriaItem = CategoriaItem.base
    var adicionadoEm: Date = Date()

    init(catalogoID: String, nome: String, categoria: CategoriaItem, adicionadoEm: Date = .now) {
        self.catalogoID = catalogoID
        self.nome = nome
        self.categoria = categoria
        self.adicionadoEm = adicionadoEm
    }

    convenience init(catalogo item: ItemCatalogo, adicionadoEm: Date = .now) {
        self.init(
            catalogoID: item.id,
            nome: item.nome,
            categoria: item.categoria,
            adicionadoEm: adicionadoEm
        )
    }
}
