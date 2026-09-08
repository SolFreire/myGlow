//
//  AppEnvironment.swift
//  myGlow
//

import Foundation
import Observation
import SwiftData


@MainActor
@Observable
final class AppEnvironment {
    let inventario: any MakeupInventoryRepository
    let progresso: any ProgressRepository
    let fotos: any FotoRepository
    //let classificador: any MakeupItemClassifying

    private(set) var roteiros: [Subcultura: Roteiro] = [:]
    private(set) var onboarding: RoteiroOnboarding?

    private(set) var erroDeRoteiro: String?

    init(
        inventario: any MakeupInventoryRepository,
        progresso: any ProgressRepository,
        fotos: any FotoRepository
        //classificador: any MakeupItemClassifying = ManualEntryClassifier()
    ) {
        self.inventario = inventario
        self.progresso = progresso
        self.fotos = fotos
        //self.classificador = classificador
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
