//
//  SubstituicoesCuradasTests.swift
//  myGlowTests
//

import Testing
@testable import myGlow

@Suite("Grounding por categoria")
struct SubstituicoesCuradasTests {
    /// A exaustividade do switch já garante em compilação que nenhuma
    /// categoria fica sem região ou sem fato — isto documenta a intenção, e
    /// pega um valor vazio que o compilador não detectaria.
    @Test("Toda categoria tem região e fato técnico não vazios", arguments: CategoriaItem.allCases)
    func todaCategoriaTemGroundingCompleto(categoria: CategoriaItem) {
        #expect(!SubstituicoesCuradas.regiao(da: categoria).isEmpty)
        #expect(!SubstituicoesCuradas.fatoTecnico(da: categoria).isEmpty)
    }

    @Test("A região só é boca, olhos ou rosto", arguments: CategoriaItem.allCases)
    func regiaoEUmaDasTres(categoria: CategoriaItem) {
        #expect(["boca", "olhos", "rosto"].contains(SubstituicoesCuradas.regiao(da: categoria)))
    }
}
