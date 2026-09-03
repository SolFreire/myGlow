//
//  CadastroViewModel.swift
//  myGlow
//

import CoreGraphics
import Foundation
import Observation

@MainActor
@Observable
final class CadastroViewModel {
    enum Modo {
        case onboarding
        case edicao

        var tituloDoBotao: String {
            switch self {
            case .onboarding: "Salvar"
            case .edicao: "Concluir"
            }
        }
    }

    let catalogo: [ItemCatalogo]
    private(set) var maleta: Set<String> = []
    private(set) var erro: String?

    private let repositorio: any MakeupInventoryRepository

    init(
        repositorio: any MakeupInventoryRepository,
        catalogo: [ItemCatalogo] = CatalogoMaquiagem.todos
    ) {
        self.repositorio = repositorio
        self.catalogo = catalogo
    }

    var quantidadeNaMaleta: Int { maleta.count }

    var itensNaMaleta: [ItemCatalogo] {
        catalogo.filter { maleta.contains($0.id) }
    }

    var itensForaDaMaleta: [ItemCatalogo] {
        catalogo.filter { !maleta.contains($0.id) }
    }

    func estaNaMaleta(_ id: String) -> Bool {
        maleta.contains(id)
    }

    func carregar() async {
        do {
            maleta = try await repositorio.idsCadastrados()
            erro = nil
        } catch {
            erro = error.localizedDescription
        }
    }


    @discardableResult
    func alternar(_ item: ItemCatalogo) async -> Bool {
        let entrou = !maleta.contains(item.id)
        do {
            if entrou {
                try await repositorio.adicionar(item)
                maleta.insert(item.id)
            } else {
                try await repositorio.remover(catalogoID: item.id)
                maleta.remove(item.id)
            }
            erro = nil
        } catch {
            erro = error.localizedDescription
        }
        return entrou
    }

    func adicionar(_ item: ItemCatalogo) async {
        guard !maleta.contains(item.id) else { return }
        await alternar(item)
    }
}


nonisolated enum ArrasteMaleta {
    static func acertou(ponto: CGPoint, maleta: CGRect, tolerancia: CGFloat = 32) -> Bool {
        guard !maleta.isEmpty else { return false }
        return maleta.insetBy(dx: -tolerancia, dy: -tolerancia).contains(ponto)
    }
}
