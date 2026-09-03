//
//  OnboardingViewModel.swift
//  myGlow
//

import Foundation
import Observation


@MainActor
@Observable
final class OnboardingViewModel {
    enum Etapa: Equatable {
        case fala(String)
        case tela(RoteiroOnboarding.Passo.Tela)
        case fim
    }

    let roteiro: RoteiroOnboarding
    private(set) var indicePasso = 0
    private(set) var indiceFala = 0
    var subculturaEscolhida: Subcultura?

    init(roteiro: RoteiroOnboarding) {
        self.roteiro = roteiro
    }

    var personagem: String { roteiro.personagem.nome }

    var etapaAtual: Etapa {
        guard indicePasso < roteiro.passos.count else { return .fim }
        let passo = roteiro.passos[indicePasso]

        switch passo.tipo {
        case .fala:
            guard let falas = passo.falas, indiceFala < falas.count else { return .fim }
            return .fala(falas[indiceFala])
        case .tela:
            guard let tela = passo.tela else { return .fim }
            return .tela(tela)
        }
    }

    func avancar() {
        guard indicePasso < roteiro.passos.count else { return }
        let passo = roteiro.passos[indicePasso]

        if passo.tipo == .fala, let falas = passo.falas, indiceFala + 1 < falas.count {
            indiceFala += 1
        } else {
            indicePasso += 1
            indiceFala = 0
        }
    }

    func escolher(_ subcultura: Subcultura) {
        subculturaEscolhida = subcultura
        avancar()
    }
}
