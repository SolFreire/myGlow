//
//  MakeupInventoryRepository.swift
//  myGlow
//

import Foundation

/// Acesso à maleta. As ViewModels falam com este protocolo, nunca com o
/// SwiftData direto — é o que permite testar com um container em memória e, se
/// um dia entrar CloudKit, trocar a fonte sem tocar em tela.
protocol MakeupInventoryRepository: Sendable {
    func todos() async throws -> [MakeupItem]
    /// Ids do catálogo já cadastrados. É o que a tela de Cadastro usa para
    /// desenhar o estado "na maleta".
    func idsCadastrados() async throws -> Set<String>
    func adicionar(_ item: ItemCatalogo) async throws
    func remover(catalogoID: String) async throws
}
