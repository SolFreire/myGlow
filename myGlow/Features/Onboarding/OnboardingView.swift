//
//  OnboardingView.swift
//  myGlow
//

import SwiftUI

struct OnboardingView: View {
    let aoTerminar: (Subcultura) -> Void

    @Environment(AppEnvironment.self) private var ambiente
    @State private var vm: OnboardingViewModel?

    var body: some View {
        Group {
            if let vm {
                conteudo(vm)
            } else {
                ZStack {
                    FundoSalao()
                    ProgressView().tint(Provisorio.destaque)
                }
            }
        }
        .task {
            if vm == nil, let roteiro = ambiente.onboarding {
                vm = OnboardingViewModel(roteiro: roteiro)
            }
        }
    }

    @ViewBuilder
    private func conteudo(_ vm: OnboardingViewModel) -> some View {
        switch vm.etapaAtual {
        case let .fala(texto):
            FalaDaEdna(personagem: vm.personagem, texto: texto) {
                vm.avancar()
            }

        case .tela(.cadastro):
            CadastroView(modo: .onboarding) { vm.avancar() }

        case .tela(.salao):
            SelecaoDeExperienciaView(papelDoCanto: .ajustes) { vm.escolher($0) }

        case .fim:
            ProgressView()
                .tint(Provisorio.destaque)
                .onAppear { aoTerminar(vm.subculturaEscolhida ?? .gotica) }
        }
    }
}


private struct FalaDaEdna: View {
    let personagem: String
    let texto: String
    let aoContinuar: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            FundoDeCena(nome: "fundo-salao")

            ArteView(nome: "personagem-edna", simbolo: "person.crop.square")
                .containerRelativeFrame(.vertical)

            BalaoDeFala(texto: texto, estilo: .padrao, rotulo: personagem, aoAvancar: aoContinuar)
                .padding(.horizontal, 96)
                .padding(.bottom, 12)
        }
        .overlay(alignment: .topLeading) {
            BotaoDoCanto(papel: .ajustes).padding(20)
        }
    }
}
