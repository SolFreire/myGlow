//
//  SwiftDataInventoryRepository.swift
//  myGlow
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataInventoryRepository: MakeupInventoryRepository {
    private let contexto: ModelContext

    init(contexto: ModelContext) {
        self.contexto = contexto
    }

    func todos() async throws -> [MakeupItem] {
        try contexto.fetch(
            FetchDescriptor<MakeupItem>(sortBy: [SortDescriptor(\.adicionadoEm)])
        )
    }

    func idsCadastrados() async throws -> Set<String> {
        Set(try await todos().map(\.catalogoID))
    }

    /// Adicionar duas vezes o mesmo item é no-op: a tela de Cadastro mostra o
    /// item já cadastrado no estado "na maleta", então duplicidade não deveria
    /// nem chegar aqui — mas a garantia fica no repositório, não na UI.
    func adicionar(_ item: ItemCatalogo) async throws {
        let id = item.id
        let existentes = try contexto.fetch(
            FetchDescriptor<MakeupItem>(predicate: #Predicate { $0.catalogoID == id })
        )
        guard existentes.isEmpty else { return }

        contexto.insert(MakeupItem(catalogo: item))
        try contexto.save()
    }

    func remover(catalogoID: String) async throws {
        let alvos = try contexto.fetch(
            FetchDescriptor<MakeupItem>(predicate: #Predicate { $0.catalogoID == catalogoID })
        )
        for alvo in alvos {
            contexto.delete(alvo)
        }
        try contexto.save()
    }
}
