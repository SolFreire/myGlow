//
//  Mocks.swift
//  myGlowTests
//

import Foundation
@testable import myGlow

/// Repositório de maleta em memória — deixa testar ViewModel sem SwiftData.
@MainActor
final class InventarioEmMemoria: MakeupInventoryRepository {
    var itens: [MakeupItem]
    var erroAoAdicionar: Error?

    init(ids: [String] = []) {
        itens = ids.compactMap { CatalogoMaquiagem.item(id: $0) }.map { MakeupItem(catalogo: $0) }
    }

    func todos() async throws -> [MakeupItem] { itens }

    func idsCadastrados() async throws -> Set<String> { Set(itens.map(\.catalogoID)) }

    func adicionar(_ item: ItemCatalogo) async throws {
        if let erroAoAdicionar { throw erroAoAdicionar }
        guard !itens.contains(where: { $0.catalogoID == item.id }) else { return }
        itens.append(MakeupItem(catalogo: item))
    }

    func remover(catalogoID: String) async throws {
        itens.removeAll { $0.catalogoID == catalogoID }
    }
}

/// Suggester falso. É um `actor` porque o protocolo é `Sendable` e o mock
/// precisa contar chamadas com segurança entre contextos.
actor SuggesterFalso: TechniqueSuggesting {
    private(set) var chamadas = 0
    private(set) var ultimoInventario: [ItemResumo] = []
    private(set) var ultimaEtapa: TutorialStep?

    private var resultado: Result<TechniqueSuggestion, SuggestionError>

    init(resultado: Result<TechniqueSuggestion, SuggestionError> = .success(Fixture.sugestao())) {
        self.resultado = resultado
    }

    func suggestTechnique(
        for step: TutorialStep,
        inventory: [ItemResumo]
    ) async throws -> TechniqueSuggestion {
        chamadas += 1
        ultimaEtapa = step
        ultimoInventario = inventory
        return try resultado.get()
    }
}

@MainActor
final class ProgressoEmMemoria: ProgressRepository {
    private(set) var etapasMarcadas: [String] = []
    private(set) var conclusoes: [Subcultura: Int] = [:]

    /// Total, sem separar por trilha — usado pelos testes do Tutorial.
    var tutoriaisConcluidos: Int { conclusoes.values.reduce(0, +) }

    func progresso(de subcultura: Subcultura) async throws -> UserProgress {
        UserProgress(
            subcultura: subcultura,
            etapasConcluidas: etapasMarcadas,
            tutoriaisConcluidos: conclusoes[subcultura] ?? 0
        )
    }

    func marcarEtapaConcluida(_ etapaID: String, em subcultura: Subcultura) async throws {
        etapasMarcadas.append(etapaID)
    }

    func marcarTutorialConcluido(_ subcultura: Subcultura) async throws {
        conclusoes[subcultura, default: 0] += 1
    }
}

/// Suggester cuja resposta o teste controla na mão — para simular duas
/// chamadas em voo ao mesmo tempo respondendo fora de ordem.
actor SuggesterControlavel: TechniqueSuggesting {
    private var pendentes: [String: CheckedContinuation<TechniqueSuggestion, Error>] = [:]

    func suggestTechnique(
        for step: TutorialStep,
        inventory: [ItemResumo]
    ) async throws -> TechniqueSuggestion {
        try await withCheckedThrowingContinuation { continuacao in
            pendentes[step.id] = continuacao
        }
    }

    func temChamadaPendente(paraEtapa id: String) -> Bool {
        pendentes[id] != nil
    }

    func resolver(etapa id: String, com sugestao: TechniqueSuggestion) {
        pendentes.removeValue(forKey: id)?.resume(returning: sugestao)
    }
}
