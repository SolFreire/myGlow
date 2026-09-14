//
//  CenaInterativa.swift
//  myGlow
//

import SwiftUI


struct CenaInterativa<Objetos: View>: View {
    let cenario: String
    let proporcaoDaArte: CGFloat
    @ViewBuilder var objetos: (CGRect) -> Objetos

    var body: some View {
        GeometryReader { proxy in
            let moldura = Self.molduraDaArte(em: proxy.size, proporcao: proporcaoDaArte)

            ZStack(alignment: .topLeading) {
                if Arte.existe(cenario) {
                    Image(cenario)
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()
                        .descricaoDaArte(cenario)
                } else {
                    FundoSalao()
                }

                objetos(moldura)
            }
        }
        .ignoresSafeArea()
    }

    static func molduraDaArte(em tamanho: CGSize, proporcao: CGFloat) -> CGRect {
        guard tamanho.width > 0, tamanho.height > 0, proporcao > 0 else { return .zero }

        let escala = max(tamanho.width / proporcao, tamanho.height)
        let largura = escala * proporcao
        let altura = escala

        return CGRect(
            x: (tamanho.width - largura) / 2,
            y: (tamanho.height - altura) / 2,
            width: largura,
            height: altura
        )
    }
}


struct ObjetoDaCena: View {
    let asset: String
    let simbolo: String
    let posicao: UnitPoint
    var ancora: UnitPoint = .center
    let largura: CGFloat
    let moldura: CGRect
    let rotulo: String
    let acao: () -> Void

    private var deslocamentoVertical: CGFloat {
        guard ancora != .center, let proporcao = Arte.proporcao(asset), proporcao > 0 else { return 0 }
        let altura = moldura.width * largura / proporcao
        return altura * (0.5 - ancora.y)
    }

    var body: some View {
        Button(action: acao) {
            ArteView(nome: asset, simbolo: simbolo)
                .frame(width: moldura.width * largura)
        }
        .buttonStyle(.plain)
        .position(
            x: moldura.minX + moldura.width * posicao.x,
            y: moldura.minY + moldura.height * posicao.y + deslocamentoVertical
        )
        .accessibilityLabel(rotulo)
    }
}

