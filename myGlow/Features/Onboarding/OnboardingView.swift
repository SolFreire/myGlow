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
                    ProgressView().tint(Cores.destaque)
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
                .tint(Cores.destaque)
                .onAppear { aoTerminar(vm.subculturaEscolhida ?? .gotica) }
        }
    }
}


private struct FalaDaEdna: View {
    let personagem: String
    let texto: String
    let aoContinuar: () -> Void

    var body: some View {
        // Mesma montagem do Tutorial: a Edna e camada do fundo, para herdar o
        // retangulo que vai ate a borda fisica da tela; o balao respeita a safe
        // area.
        FundoDeCena(nome: "fundo-salao")
            .overlay {
                GeometryReader { proxy in
                    ArteView(nome: "personagem-edna", simbolo: "person.crop.square")
                        .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
                }
                .ignoresSafeArea()
            }
            .overlay(alignment: .bottom) {
                BalaoDeFala(texto: texto, estilo: .padrao, rotulo: personagem, aoAvancar: aoContinuar)
                    .padding(.horizontal, 96)
                    .padding(.bottom, 12)
            }
            .overlay(alignment: .topLeading) {
                BotaoDoCanto(papel: .ajustes).padding(20)
            }
    }
}
