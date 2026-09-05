//
//  TelaEmConstrucao.swift
//  myGlow
//

import SwiftUI


struct TelaEmConstrucao<Acoes: View>: View {
    let titulo: String
    var papelDoCanto: PapelDoCanto = .voltarAoSalao
    @ViewBuilder var acoes: Acoes

    var body: some View {
        ZStack {
            FundoSalao(cor: Paleta.botao.base)

            VStack(spacing: 24) {
                Text(titulo)
                    .font(Tipografia.titulo)
                    .foregroundStyle(Provisorio.texto)

//                Text("Aguardando o desenho do design.")
//                    .font(Tipografia.corpo)
//                    .foregroundStyle(Provisorio.textoSecundario)

                acoes
            }
            .multilineTextAlignment(.center)
            .padding(32)
        }
        .overlay(alignment: .topLeading) { BotaoDoCanto(papel: papelDoCanto).padding(20) }
    }
}
