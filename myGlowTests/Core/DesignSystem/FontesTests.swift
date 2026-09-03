//
//  FontesTests.swift
//  myGlowTests
//

import Testing
@testable import myGlow

/// Fonte que não entra no bundle não quebra o build nem lança erro: o app
/// simplesmente desenha com a fonte do sistema e ninguém percebe até alguém
/// olhar a tela. Este teste é o que torna isso visível.
@Suite("Tipografia")
struct FontesTests {
    @Test("As três variantes da Life Savers estão no bundle e registram")
    func registram() {
        Fontes.registrar()

        #expect(
            Fontes.disponiveis.sorted() == [
                Fontes.lifeSaversBold,
                Fontes.lifeSaversExtraBold,
                Fontes.lifeSaversRegular
            ].sorted()
        )
    }

    @Test("Registrar duas vezes não quebra")
    func registroIdempotente() {
        Fontes.registrar()
        Fontes.registrar()

        #expect(Fontes.disponiveis.count == 3)
    }
}
