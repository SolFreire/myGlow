//
//  StaticRulesSuggesterTests.swift
//  myGlowTests
//

import Testing
@testable import myGlow

@Suite("Fallback por regras estáticas")
struct StaticRulesSuggesterTests {
    private let suggester = StaticRulesSuggester(roteiro: Fixture.roteiro())

    @Test("Sugere o lápis preto quando falta a caneta delineadora")
    func substituicaoConhecida() async throws {
        let sugestao = try await suggester.suggestTechnique(
            for: Fixture.etapa(itensNecessarios: ["caneta-delineadora"]),
            inventory: Fixture.resumos("lapis-preto", "batom")
        )

        #expect(sugestao.substituicoes.count == 1)
        #expect(sugestao.substituicoes.first?.itemAusente == "Caneta delineadora")
        #expect(sugestao.substituicoes.first?.itemUsado == "Lápis preto")
        #expect(sugestao.origem == .regrasEstaticas)
    }

    @Test("Sem nenhum substituto na maleta, não inventa substituição")
    func semRegraAplicavel() async throws {
        let sugestao = try await suggester.suggestTechnique(
            for: Fixture.etapa(itensNecessarios: ["cilios-posticos"]),
            inventory: Fixture.resumos("batom")
        )

        #expect(sugestao.substituicoes.isEmpty)
    }

    @Test("Os passos vêm das falas de instrução do roteiro, não de texto inventado")
    func passosVemDoRoteiro() async throws {
        let etapa = Fixture.etapa(
            itensNecessarios: ["clown"],
            falas: [
                Fixture.fala(.introducao, "Vamos começar pela pele."),
                Fixture.fala(.instrucaoPratica, "Aplique em batidinhas firmes."),
                Fixture.fala(.contextoHistorico, "A base branca vem do pós-punk.")
            ]
        )

        let sugestao = try await suggester.suggestTechnique(
            for: etapa,
            inventory: Fixture.resumos("base")
        )

        #expect(sugestao.passos == ["Aplique em batidinhas firmes."])
        #expect(sugestao.curiosidade == "A base branca vem do pós-punk.")
    }

    @Test("Não marca itens como não utilizados — não há modelo para restringir")
    func naoUtilizadosFicaVazio() async throws {
        let sugestao = try await suggester.suggestTechnique(
            for: Fixture.etapa(itensNecessarios: ["caneta-delineadora"]),
            inventory: Fixture.resumos("lapis-preto", "bronzer-inexistente", "gloss")
        )

        #expect(sugestao.itensNaoUtilizados.isEmpty)
    }
}
