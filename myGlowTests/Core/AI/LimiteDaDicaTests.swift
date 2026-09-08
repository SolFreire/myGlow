//
//  LimiteDaDicaTests.swift
//  myGlowTests
//

import Testing
@testable import myGlow

@Suite("Limite de tamanho da dica")
struct LimiteDaDicaTests {
    @Test("Corta no fim de frase quando passa do limite")
    func cortaEmFraseCompleta() {
        let texto = String(repeating: "Use o lápis preto para desenhar a linha. ", count: 10)
        let cortado = LimiteDaDica.aplicar(texto)

        #expect(cortado.count <= LimiteDaDica.caracteres + 1)
        #expect(cortado.hasSuffix("."))
    }

    @Test("Não mexe em texto já curto")
    func mantemTextoCurto() {
        #expect(LimiteDaDica.aplicar("Sem gloss? Use iluminador.") == "Sem gloss? Use iluminador.")
    }

    @Test("Sem ponto final no trecho cortado, corta na última palavra inteira")
    func cortaEmPalavraCompleta() {
        let texto = String(repeating: "palavra ", count: 40) // 320 caracteres, sem ponto
        let cortado = LimiteDaDica.aplicar(texto)

        #expect(cortado.hasSuffix("…"))
        #expect(cortado.count <= LimiteDaDica.caracteres + 1)
        #expect(cortado.dropLast().hasSuffix("palavra"), "Não pode cortar no meio de uma palavra")
    }
}
