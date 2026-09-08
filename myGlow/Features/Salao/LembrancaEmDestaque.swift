//
//  LembrancaEmDestaque.swift
//  myGlow
//

import SwiftUI

/// O objeto que cada trilha deixa no salão.
///
/// Arte e texto andam juntos porque descrevem a mesma coisa; onde ele fica na
/// cena é problema do salão, e mora lá.
nonisolated struct Lembranca {
    let asset: String
    let simbolo: String
    let rotulo: String
    let texto: String
}

extension Subcultura {
    /// Segue o padrão de `rotuloDeContexto`: texto de tela mora numa extensão
    /// perto de quem usa, e não dentro do enum — que é modelo de domínio,
    /// `Codable` e persistido pelo SwiftData.
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

/// A lembrança aberta, sobre o salão.
///
/// Não é uma tela: o salão continua atrás, escurecido, e o objeto cresce do
/// lugar dele na estante. É o que dá a leitura de "isto é seu, e está ali" —
/// uma tela empurrada quebraria essa ligação.
struct LembrancaEmDestaque: View {
    let subcultura: Subcultura
    let animacao: Namespace.ID
    let aoFechar: () -> Void

    /// O overlay e modal: sem levar o foco para dentro, o VoiceOver continua
    /// no objeto da estante e a pessoa nao ouve o que abriu.
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

                // Depois do balão, de propósito: a ilustração passa por cima
                // dele. É o que dá a leitura de objeto na frente e fala atrás,
                // em vez de uma etiqueta colada sobre o troféu.
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
        // Qualquer ponto fecha — inclusive sobre o balão. `contentShape` faz o
        // vão entre os elementos contar como área tocável.
        .contentShape(Rectangle())
        .onTapGesture(perform: aoFechar)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape, aoFechar)
    }

    /// O contorno branco não está no asset: são sombras brancas empilhadas, a
    /// mesma técnica que o Tutorial usa para destacar a personagem no foco.
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

    /// Tiradas do mockup, em fração da cena.
    private enum Medida {
        static let veu = 0.45
        /// Pela **altura**, e nao pela largura: a proporcao da cena varia muito
        /// entre um iPhone deitado (~2,2) e um iPad (~1,2), e uma fracao de
        /// largura faria o objeto ocupar 62% da tela num e 34% no outro.
        static let alturaDoObjeto: CGFloat = 0.62
        static let centroDoObjeto = UnitPoint(x: 0.68, y: 0.40)
        static let larguraDoBalao: CGFloat = 0.34
        static let centroDoBalao = UnitPoint(x: 0.45, y: 0.64)
    }
}
