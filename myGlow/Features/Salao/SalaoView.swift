//
//  SalaoView.swift
//  myGlow
//

import SwiftUI

struct SalaoView: View {

    let desbloqueadas: Set<Subcultura>
    let aoSentar: () -> Void
    let aoNavegar: (AppRoute) -> Void

    @State private var lembrancaAberta: Subcultura?
    @Namespace private var animacaoDaLembranca

    var body: some View {
        CenaInterativa(cenario: "fundo-salao-menu", proporcaoDaArte: Cena.proporcao) { moldura in
            objetos(moldura)
        }
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .topLeading) { BotaoDoCanto(papel: .ajustes).padding(20) }
        .overlay {
            if let subcultura = lembrancaAberta {
                LembrancaEmDestaque(subcultura: subcultura, animacao: animacaoDaLembranca) {
                    withAnimation(.snappy) { lembrancaAberta = nil }
                }
            }
        }
    }

    @ViewBuilder
    private func objetos(_ moldura: CGRect) -> some View {
        ObjetoDaCena(
            asset: "icone-cadeira-salao",
            simbolo: "chair.lounge.fill",
            posicao: Cena.cadeira,
            ancora: .bottom,
            largura: 0.145,
            moldura: moldura,
            rotulo: "Sentar e escolher a experiência",
            acao: aoSentar
        )

        ObjetoDaCena(
            asset: "icone-maleta",
            simbolo: "bag.fill",
            posicao: Cena.maleta,
            largura: 0.110,
            moldura: moldura,
            rotulo: "Minha maleta"
        ) {
            aoNavegar(.cadastro)
        }

        ObjetoDaCena(
            asset: "icone-album-fotos",
            simbolo: "photo.stack.fill",
            posicao: Cena.album,
            largura: 0.086,
            moldura: moldura,
            rotulo: "Meu álbum"
        ) {
            aoNavegar(.galeria)
        }


        ForEach(Subcultura.allCases.filter(desbloqueadas.contains)) { subcultura in
            let lugar = Cena.lembranca(de: subcultura)

            if lembrancaAberta != subcultura {
                ObjetoDaCena(
                    asset: subcultura.lembranca.asset,
                    simbolo: subcultura.lembranca.simbolo,
                    posicao: lugar.posicao,
                    largura: lugar.largura,
                    moldura: moldura,
                    rotulo: "Lembrança de \(subcultura.personagem)"
                ) {
                    withAnimation(.snappy) { lembrancaAberta = subcultura }
                }
                .matchedGeometryEffect(id: subcultura, in: animacaoDaLembranca)
            }
        }
    }

    private enum Cena {
        static let proporcao: CGFloat = 852.0 / 393.0

        static let cadeira = UnitPoint(x: 0.350, y: 0.875)
        static let maleta = UnitPoint(x: 0.48, y: 0.295)
        static let album = UnitPoint(x: 0.177, y: 0.341)


        static func lembranca(de subcultura: Subcultura) -> (posicao: UnitPoint, largura: CGFloat) {
            switch subcultura {
            case .gotica: (UnitPoint(x: 0.518, y: 0.450), 0.075)
            case .gyaru: (UnitPoint(x: 0.826, y: 0.562), 0.088)
            case .newRomantic: (UnitPoint(x: 0.448, y: 0.518), 0.062)
            }
        }
    }
}
#Preview("Salão com as três lembranças", traits: .landscapeLeft) {
    SalaoView(
        desbloqueadas: [.gotica, .gyaru, .newRomantic],
        aoSentar: {},
        aoNavegar: { _ in }
    )
}

#Preview("Salão sem nenhuma conquista", traits: .landscapeLeft) {
    SalaoView(desbloqueadas: [.gotica,.gyaru,.newRomantic], aoSentar: {}, aoNavegar: { _ in })
}
