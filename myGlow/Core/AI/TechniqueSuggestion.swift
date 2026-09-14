//
//  TechniqueSuggestion.swift
//  myGlow
//

import Foundation


nonisolated struct ItemResumo: Hashable, Sendable, Identifiable {
    let id: String
    let nome: String
    let categoria: String

    init(_ item: MakeupItem) {
        self.id = item.catalogoID
        self.nome = item.nome
        self.categoria = item.categoria.nome
    }

    init(id: String, nome: String, categoria: String) {
        self.id = id
        self.nome = nome
        self.categoria = categoria
    }
}


nonisolated struct TechniqueSuggestion: Equatable, Sendable {

    enum Origem: String, Equatable, Sendable {
        case onDevice
        case regrasEstaticas
    }

    let dica: String

    let origem: Origem
}
