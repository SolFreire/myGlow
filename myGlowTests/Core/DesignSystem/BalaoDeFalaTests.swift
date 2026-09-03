//
//  BalaoDeFalaTests.swift
//  myGlowTests
//

import SwiftUI
import UIKit
import Testing
@testable import myGlow

@Suite("Balão de fala")
@MainActor
struct BalaoDeFalaTests {

    @Test("O balão de contexto não usa a mesma cor do balão comum")
    func contextoTemCorPropria() {
        #expect(
            distanciaEntreCores(BalaoDeFala.Cor.borda, BalaoDeFala.Cor.contexto) > 0.3,
            "É a cor que diz, sem precisar ler, que ali é contexto e não instrução"
        )
    }

    @Test("O texto do balão contrasta com o fundo do balão")
    func balaoLegivel() {
        #expect(distanciaEntreCores(BalaoDeFala.Cor.texto, BalaoDeFala.Cor.fundo) > 1.5)
    }

    /// Os botões de navegar ficam por cima da borda do balão. No contexto
    /// histórico o roxo padrão destoaria dela.
    @Test("Os botões acompanham a cor do balão")
    func botoesAcompanhamOBalao() {
        #expect(BalaoDeFala.Estilo.contexto.botoes.nomeDaBase == Paleta.botaoDeContexto.nomeDaBase)
        for estilo in [BalaoDeFala.Estilo.padrao, .passo] {
            #expect(estilo.botoes.nomeDaBase == Paleta.botao.nomeDaBase)
        }
    }

    /// A aba com o nome da personagem é uma cápsula centrada na borda de cima:
    /// metade dela invade o balão. Se o recuo do topo não cobrir essa metade,
    /// ela passa por cima da primeira linha do texto.
    ///
    /// A altura sai do estilo `.headline`, que é o que `nomeDaPersonagem`
    /// acompanha no Dynamic Type — então o teste vale também para quem aumenta
    /// a fonte nos Ajustes.
    @Test("A aba não cobre a primeira linha do texto")
    func abaNaoCobreOTexto() {
        let alturaDaAba = UIFont.preferredFont(forTextStyle: .headline).lineHeight
            + 2 * BalaoDeFala.Medida.recuoVerticalDaAba

        #expect(BalaoDeFala.Medida.recuoDaAba > alturaDaAba / 2)
    }

    /// O botão de avançar se projeta `diametro / 4` para fora da borda. O espaço
    /// reservado à direita precisa cobrir o resto, senão o texto passa por baixo.
    @Test("O texto não passa por baixo do botão de avançar")
    func textoNaoPassaSobOBotao() {
        let invasao = BalaoDeFala.Medida.diametroDoBotao * 3 / 4
        #expect(BalaoDeFala.Medida.espacoDoBotao >= invasao - BalaoDeFala.Medida.recuoHorizontal)
    }
}
