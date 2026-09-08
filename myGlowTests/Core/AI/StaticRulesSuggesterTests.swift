//
//  StaticRulesSuggesterTests.swift
//  myGlowTests
//

import Foundation
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

        #expect(sugestao.dica.contains("Caneta delineadora"))
        #expect(sugestao.dica.contains("Lápis preto"))
        #expect(sugestao.origem == .regrasEstaticas)
    }

    @Test("Sem nenhum substituto na maleta, não inventa substituição")
    func semRegraAplicavel() async throws {
        let sugestao = try await suggester.suggestTechnique(
            for: Fixture.etapa(itensNecessarios: ["cilios-posticos"]),
            inventory: Fixture.resumos("batom")
        )

        #expect(sugestao.dica == "Com o que você já tem na maleta dá pra seguir esta etapa do jeitinho do roteiro.")
    }

    /// Achado empírico: 7 das 19 etapas de passo nos três roteiros pedem dois
    /// itens ao mesmo tempo (ex: `gotica-base`, clown+pancake). Uma dica que só
    /// resolve o primeiro deixaria a pessoa sem solução pra metade do problema.
    @Test("Com dois itens faltando, a dica cobre os dois")
    func dicaComDoisItensFaltando() async throws {
        let etapa = Fixture.etapa(itensNecessarios: ["clown", "pancake"])

        // "po" é substituto de ambos na tabela de regras — sem ele na maleta,
        // nenhuma regra se aplicaria e a dica cairia no genérico "case 0".
        let sugestao = try await suggester.suggestTechnique(for: etapa, inventory: Fixture.resumos("po"))

        #expect(sugestao.dica.localizedCaseInsensitiveContains("clown"))
        #expect(sugestao.dica.localizedCaseInsensitiveContains("pancake"))
    }

    @Test("A dica não cita produto fora da maleta")
    func naoCitaProdutoDeFora() async throws {
        let etapa = Fixture.etapa(itensNecessarios: ["caneta-delineadora"])
        let maleta = Fixture.resumos("lapis-preto", "gloss")

        let sugestao = try await suggester.suggestTechnique(for: etapa, inventory: maleta)

        let faltantes = etapa.itensFaltantes(naMaleta: Set(maleta.map(\.id)))
        let catalogoParaChecagem = CatalogoMaquiagem.todos.filter { !faltantes.contains($0.id) }
        let foraDaMaleta = ChecagemDeInventario.itensForaDaMaleta(
            emTextos: [sugestao.dica],
            maleta: maleta,
            catalogo: catalogoParaChecagem
        )
        #expect(foraDaMaleta.isEmpty)
    }
}
