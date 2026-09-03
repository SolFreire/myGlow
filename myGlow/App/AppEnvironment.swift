//
//  AppEnvironment.swift
//  myGlow
//

import Foundation
import Observation
import SwiftData

/// Container leve de dependências, injetado com `.environment()` na raiz.
///
/// Para o tamanho deste app um `@Observable` com os serviços como propriedades
/// basta — não vale a complexidade de um framework de DI (§13 do levantamento).
@MainActor
@Observable
final class AppEnvironment {
    let inventario: any MakeupInventoryRepository
    let progresso: any ProgressRepository
    let fotos: any FotoRepository
    let classificador: any MakeupItemClassifying
    let rolo: any PhotoLibrarySaving

    private(set) var roteiros: [Subcultura: Roteiro] = [:]
    private(set) var onboarding: RoteiroOnboarding?
    /// Preenchido se algum JSON do bundle não pôde ser lido. A tela mostra isso
    /// em vez de aparecer vazia sem explicação.
    private(set) var erroDeRoteiro: String?

    init(
        inventario: any MakeupInventoryRepository,
        progresso: any ProgressRepository,
        fotos: any FotoRepository,
        classificador: any MakeupItemClassifying = ManualEntryClassifier(),
        rolo: any PhotoLibrarySaving = PhotoLibraryService()
    ) {
        self.inventario = inventario
        self.progresso = progresso
        self.fotos = fotos
        self.classificador = classificador
        self.rolo = rolo
        carregarRoteiros()
    }

    convenience init(contexto: ModelContext) {
        self.init(
            inventario: SwiftDataInventoryRepository(contexto: contexto),
            progresso: SwiftDataProgressRepository(contexto: contexto),
            fotos: SwiftDataFotoRepository(contexto: contexto)
        )
    }

    func roteiro(de subcultura: Subcultura) -> Roteiro? {
        roteiros[subcultura]
    }

    /// A ViewModel do Tutorial recebe isto e nunca sabe qual implementação veio.
    func suggester(para subcultura: Subcultura) -> (any TechniqueSuggesting)? {
        guard let roteiro = roteiros[subcultura] else { return nil }
        return TechniqueSuggesterFactory.make(roteiro: roteiro)
    }

    private func carregarRoteiros() {
        do {
            roteiros = try RoteiroLoader.carregarTodos()
            onboarding = try RoteiroLoader.carregarOnboarding()
            erroDeRoteiro = nil
        } catch {
            erroDeRoteiro = error.localizedDescription
        }
    }
}
