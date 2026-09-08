//
//  TelaInicialView.swift
//  myGlow
//

import SwiftUI


struct TelaInicialView: View {
    let aoJogar: () -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            fundo
            BotaoPrimario(titulo: "Jogar", tamanho: .grande, preencheLargura: false){
                SoundManager.shared.playSoundEffect(named: "botao-efeito")
                aoJogar()
            }
                .accessibilityIdentifier("jogar")
                .padding(.bottom, 28)
        }
        .ignoresSafeArea()
        .overlay(alignment: .topLeading) { BotaoDoCanto(papel: .ajustes).padding(20) }
    }

    @ViewBuilder
    private var fundo: some View {

        GeometryReader { proxy in
            Image("fundo-tela-inicial")
                .resizable()
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
        }
        .descricaoDaArte("fundo-tela-inicial")
    }
}

#Preview("Tela Inicial", traits: .landscapeLeft) {
    TelaInicialView { }
}
