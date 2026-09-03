//
//  PaletaTests.swift
//  myGlowTests
//

import SwiftUI
import UIKit
import Testing
@testable import myGlow

/// Distância entre duas cores, somando as diferenças de canal. Não é medida
/// perceptual — serve só para separar "são cores diferentes" de "são a mesma".
@MainActor
func distanciaEntreCores(_ a: Color, _ b: Color) -> Double {
    let ambiente = EnvironmentValues()
    let x = a.resolve(in: ambiente)
    let y = b.resolve(in: ambiente)
    return Double(abs(x.red - y.red) + abs(x.green - y.green) + abs(x.blue - y.blue))
}

@Suite("Paleta")
@MainActor
struct PaletaTests {

    /// Um Color Set com nome errado não quebra nada: `Color(_:)` devolve preto
    /// e o botão só fica escuro. Foi o que aconteceu com
    /// `cor-botao-secundari**a**-claro`, que no catálogo é `secundari**o**`.
    @Test("Todo Color Set da Paleta existe no catálogo", arguments: Paleta.familiasDeBotao)
    func corExisteNoCatalogo(familia: Paleta.Botao) {
        #expect(UIColor(named: familia.nomeDaBase) != nil, "Color Set ausente: \(familia.nomeDaBase)")
        #expect(UIColor(named: familia.nomeDoClaro) != nil, "Color Set ausente: \(familia.nomeDoClaro)")
    }

    /// Um degradê sem contraste não quebra nada: o botão só fica chapado e
    /// ninguém percebe até alguém olhar a tela. Foi o que aconteceu quando as
    /// duas pontas derivavam do mesmo roxo com variação pequena demais.
    @Test("O degradê do botão tem contraste visível", arguments: Paleta.familiasDeBotao)
    func degradeTemContraste(familia: Paleta.Botao) {
        #expect(
            distanciaEntreCores(familia.claro, familia.base) > 0.25,
            "As pontas do degradê ficaram próximas demais — o botão sai chapado"
        )
    }

    @Test("A sombra é mais escura que o botão", arguments: Paleta.familiasDeBotao)
    func sombraEscurece(familia: Paleta.Botao) {
        #expect(distanciaEntreCores(familia.escuro, familia.base) > 0.05)
    }

    @Test("O ciano do contexto não é o roxo padrão")
    func familiasSaoDistintas() {
        #expect(distanciaEntreCores(Paleta.botao.base, Paleta.botaoDeContexto.base) > 0.3)
    }
}
