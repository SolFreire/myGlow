//
//  RotuloIlustrado.swift
//  myGlow
//

import SwiftUI

struct RotuloIlustrado: View {
    let texto: String
    var tamanho: CGFloat = 20
    var larguraDoTraco: CGFloat = 1.4
    var corDoTraco: Color = .white
    var corDoPreenchimento: Color = Cores.destaque
    var linhas = 2
    var espacamentoEntreLinhas: CGFloat = 0.4

    private static let direcoes: [CGSize] = [
        CGSize(width: -1, height: -1), CGSize(width: 0, height: -1), CGSize(width: 1, height: -1),
        CGSize(width: -1, height: 0), CGSize(width: 1, height: 0),
        CGSize(width: -1, height: 1), CGSize(width: 0, height: 1), CGSize(width: 1, height: 1)
    ]

    private var fonte: Font {
        .custom(Fontes.lifeSaversExtraBold, size: tamanho)
    }

    var body: some View {
        ZStack {
            ForEach(Array(Self.direcoes.enumerated()), id: \.offset) { _, direcao in
                corpo(cor: corDoTraco)
                    .offset(x: direcao.width * larguraDoTraco, y: direcao.height * larguraDoTraco)
            }
            corpo(cor: corDoPreenchimento)
        }
        .accessibilityHidden(true)
    }

    private func corpo(cor: Color) -> some View {
        Text(texto)
            .font(fonte)
            .foregroundStyle(cor)
            .multilineTextAlignment(.center)
            .lineLimit(linhas)
            .lineSpacing(espacamentoEntreLinhas)
            .minimumScaleFactor(0.8)
    }
}
