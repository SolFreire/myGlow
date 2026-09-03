//
//  MakeupInventoryRepository.swift
//  myGlow
//

import Foundation


protocol MakeupInventoryRepository: Sendable {
    func todos() async throws -> [MakeupItem]
    func idsCadastrados() async throws -> Set<String>
    func adicionar(_ item: ItemCatalogo) async throws
    func remover(catalogoID: String) async throws
}
