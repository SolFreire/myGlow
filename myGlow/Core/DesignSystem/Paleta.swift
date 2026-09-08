//
//  Paleta.swift
//  myGlow
//

import SwiftUI


enum Paleta {

    struct Botao {
        let nomeDaBase: String
        let nomeDoClaro: String

        var base: Color { Color(nomeDaBase) }
        var claro: Color { Color(nomeDoClaro) }
        var escuro: Color { base.mix(with: .black, by: 0.18) }
        var gradiente: LinearGradient {
            LinearGradient(
                stops: [
                    .init(color: claro, location: 0),
                    .init(color: base, location: 0.25)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    static let botao = Botao(nomeDaBase: "cor-botao", nomeDoClaro: "cor-botao-claro")

    static let botaoDeContexto = Botao(
        nomeDaBase: "cor-balao-borda-secundaria",
        nomeDoClaro: "cor-botao-secundario-claro"
    )

    static let botaoDeSugestao = Botao(
        nomeDaBase: "cor-balao-sugestao",
        nomeDoClaro: "cor-botao-terciario-claro"
    )

    static let familiasDeBotao = [botao, botaoDeContexto, botaoDeSugestao]
}
