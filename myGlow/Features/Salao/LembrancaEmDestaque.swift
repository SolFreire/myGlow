//
//  LembrancaEmDestaque.swift
//  myGlow
//

import SwiftUI

nonisolated struct Lembranca {
    let asset: String
    let simbolo: String
    let rotulo: String
    let texto: String
}

extension Subcultura {

    var lembranca: Lembranca {
        switch self {
        case .gotica:
            Lembranca(
                asset: "icone-aranha-lucy",
                simbolo: "ant.fill",
                rotulo: "Spider",
                texto: "Uma lembrancinha da Lucy pela sua incrível maquiagem gótica"
            )
        case .gyaru:
            Lembranca(
                asset: "icone-urso-sana",
                simbolo: "teddybear.fill",
                rotulo: "Bear",
                texto: "Uma lembrancinha da Sana pela sua fofa maquiagem gyaru"
            )
        case .newRomantic:
            Lembranca(
                asset: "icone-disco-cindy",
                simbolo: "opticaldisc.fill",
                rotulo: "Disco",
                texto: "Uma lembrancinha da Cindy pela sua maquiagem New Romantics Eletrizante"
            )
        }
    }
}


struct LembrancaEmDestaque: View {
    let subcultura: Subcultura
    let animacao: Namespace.ID
    let aoFechar: () -> Void


    @AccessibilityFocusState private var falaEmFoco: Bool

    var body: some View {
        GeometryReader { proxy in
            let cena = proxy.size

            ZStack {
                Color.black.opacity(Medida.veu)

                fala
                    .accessibilityFocused($falaEmFoco)
                    .onAppear { falaEmFoco = true }
                    .frame(width: cena.width * Medida.larguraDoBalao)
                    .position(
                        x: cena.width * Medida.centroDoBalao.x,
                        y: cena.height * Medida.centroDoBalao.y
                    )

                objeto
                    .frame(height: cena.height * Medida.alturaDoObjeto)
                    .matchedGeometryEffect(id: subcultura, in: animacao)
                    .position(
                        x: cena.width * Medida.centroDoObjeto.x,
                        y: cena.height * Medida.centroDoObjeto.y
                    )
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture(perform: aoFechar)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, aoFechar)
    }


    private var objeto: some View {
        ArteView(nome: subcultura.lembranca.asset, simbolo: subcultura.lembranca.simbolo)
            .shadow(color: .white, radius: 2)
            .shadow(color: .white, radius: 5)
            .shadow(color: .white.opacity(0.5), radius: 16)
    }

    private var fala: some View {
        VStack(spacing: 10) {
            BalaoDeFala(texto: subcultura.lembranca.texto, rotulo: subcultura.lembranca.rotulo)

            Text("Toque em qualquer lugar para fechar")
                .font(Tipografia.legenda)
                .foregroundStyle(.white.opacity(0.85))
        }
    }


    private enum Medida {
        static let veu = 0.45
        static let alturaDoObjeto: CGFloat = 0.62
        static let centroDoObjeto = UnitPoint(x: 0.68, y: 0.40)
        static let larguraDoBalao: CGFloat = 0.34
        static let centroDoBalao = UnitPoint(x: 0.45, y: 0.64)
    }
}
