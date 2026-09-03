//
//  OnboardingViewModelTests.swift
//  myGlowTests
//

import Testing
@testable import myGlow

@Suite("Primeiro uso com a Edna")
@MainActor
struct OnboardingViewModelTests {
    private func vmDoBundle() throws -> OnboardingViewModel {
        OnboardingViewModel(roteiro: try RoteiroLoader.carregarOnboarding())
    }

    @Test("Percorre falas e telas na ordem do roteiro")
    func percorreNaOrdem() throws {
        let vm = try vmDoBundle()

        // Duas falas de abertura, depois o cadastro.
        guard case .fala = vm.etapaAtual else { Issue.record("Esperava fala"); return }
        vm.avancar()
        guard case .fala = vm.etapaAtual else { Issue.record("Esperava a segunda fala"); return }
        vm.avancar()
        #expect(vm.etapaAtual == .tela(.cadastro))

        vm.avancar()
        guard case .fala = vm.etapaAtual else { Issue.record("Esperava a fala pós-cadastro"); return }

        vm.avancar()
        #expect(vm.etapaAtual == .tela(.salao))
    }

    @Test("Escolher a experiência guarda a subcultura e avança")
    func escolhaAvanca() throws {
        let vm = try vmDoBundle()
        while vm.etapaAtual != .tela(.salao) {
            vm.avancar()
        }

        vm.escolher(.gyaru)

        #expect(vm.subculturaEscolhida == .gyaru)
        guard case .fala = vm.etapaAtual else {
            Issue.record("Depois da escolha vem a fala que chama a especialista")
            return
        }
    }

    @Test("O fluxo termina depois da última fala")
    func terminaNoFim() throws {
        let vm = try vmDoBundle()
        for _ in 0..<20 where vm.etapaAtual != .fim {
            vm.avancar()
        }

        #expect(vm.etapaAtual == .fim)
    }
}
