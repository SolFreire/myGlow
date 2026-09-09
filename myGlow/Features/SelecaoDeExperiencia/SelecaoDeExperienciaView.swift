//
//  SelecaoDeExperienciaView.swift
//  myGlow
//

import SwiftUI


struct SelecaoDeExperienciaView: View {

    var papelDoCanto: PapelDoCanto = .voltarAoSalao
    let aoEscolher: (Subcultura) -> Void

    @Environment(AppEnvironment.self) private var ambiente
    @State private var focada: Subcultura?
    @Namespace private var animacaoDoFoco

    var body: some View {
        ZStack {
            Image("fundo-selecao-experiencia")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Escolha a experiência")
                    .font(Tipografia.titulo)
                    .foregroundStyle(Color.corBotao)

                ZStack {
                    ForEach(Subcultura.allCases) { subcultura in
                        if focada != subcultura {
                            CardMaqueadora(
                                background: "\(subcultura.backgroundCard)",
                                character: "\(subcultura.character)",
                                nomeDaPersonagem: "\(subcultura.personagem)",
                                descricao: "\(subcultura.descricao)",
                                cor: "\(subcultura.corCard)"
                            ) {
                                withAnimation(.snappy) { focada = subcultura }
                                SoundManager.shared.playSoundEffect(named: "botao-efeito")
                            }
                            .rotationEffect(.degrees(subcultura.rotation))
                            .offset(x: CGFloat(subcultura.x), y: CGFloat(subcultura.y))
                            .matchedGeometryEffect(id: subcultura, in: animacaoDoFoco)
                        }
                    }
                }
            }
            .multilineTextAlignment(.center)
            .padding(32)
        }
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .topLeading) { BotaoDoCanto(papel: papelDoCanto).padding(20) }
        .overlay {
            if let focada {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .contentShape(Rectangle())
                        .onTapGesture { withAnimation(.snappy) { self.focada = nil } }

                    VStack(spacing: 40) {
                        card(para: focada, emFoco: true) {
                            aoEscolher(focada)
                            SoundManager.shared.playSoundEffect(named: "botao-efeito")
                        }
                        .scaleEffect(1.3)

                        Text("Toque em qualquer lugar para fechar")
                            .font(Tipografia.legenda)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func card(para subcultura: Subcultura, emFoco: Bool, acao: @escaping () -> Void) -> some View {
        CardMaqueadora(
            background: "\(subcultura.backgroundCard)",
            character: "\(subcultura.character)",
            nomeDaPersonagem: "\(subcultura.personagem)",
            descricao: "\(subcultura.descricao)",
            cor: "\(subcultura.corCard)",
            emFoco: emFoco,
            acao: acao
        )
        .matchedGeometryEffect(id: subcultura, in: animacaoDoFoco)
    }

    private func nome(de subcultura: Subcultura) -> String {
        ambiente.roteiro(de: subcultura)?.personagem.nome ?? subcultura.personagem
    }
}
