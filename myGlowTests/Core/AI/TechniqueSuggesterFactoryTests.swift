//
//  TechniqueSuggesterFactoryTests.swift
//  myGlowTests
//

import Foundation
import FoundationModels
import Testing
@testable import myGlow

/// A disponibilidade entra por parâmetro justamente para este teste rodar em
/// qualquer máquina — inclusive no CI, que não tem iPhone 15 Pro.
@Suite("Escolha da implementação de sugestão")
struct TechniqueSuggesterFactoryTests {
    /// Com o modelo disponível a fábrica não devolve o on-device puro: devolve
    /// ele com as regras estáticas atrás, porque o availability do sistema já se
    /// provou não confiável em execução.
    @Test("Com Apple Intelligence disponível, usa o on-device com rede embaixo")
    func escolheOnDevice() throws {
        let suggester = TechniqueSuggesterFactory.make(
            roteiro: Fixture.roteiro(),
            disponibilidade: .available
        )

        let comFallback = try #require(suggester as? SuggesterComFallback)
        #expect(comFallback.principal is FoundationModelsSuggester)
        #expect(comFallback.reserva is StaticRulesSuggester)
    }

    @Test(
        "Sem Apple Intelligence, cai nas regras estáticas",
        arguments: [
            SystemLanguageModel.Availability.UnavailableReason.deviceNotEligible,
            .appleIntelligenceNotEnabled,
            .modelNotReady
        ]
    )
    func escolheFallback(_ motivo: SystemLanguageModel.Availability.UnavailableReason) {
        let suggester = TechniqueSuggesterFactory.make(
            roteiro: Fixture.roteiro(),
            disponibilidade: .unavailable(motivo)
        )
        #expect(suggester is StaticRulesSuggester)
    }

    /// A PoC pede exibir o motivo bruto do `.unavailable`: já houve caso de o
    /// availability dizer "disponível" com o modelo ainda baixando.
    @Test("O diagnóstico diferencia cada motivo")
    func diagnosticoPorMotivo() {
        let textos = [
            TechniqueSuggesterFactory.diagnostico(.available),
            TechniqueSuggesterFactory.diagnostico(.unavailable(.deviceNotEligible)),
            TechniqueSuggesterFactory.diagnostico(.unavailable(.appleIntelligenceNotEnabled)),
            TechniqueSuggesterFactory.diagnostico(.unavailable(.modelNotReady))
        ]
        #expect(Set(textos).count == textos.count)
    }
}

/// Escolher a implementação uma vez, na fábrica, não basta: o
/// `SystemLanguageModel.availability` já respondeu `.available` e a chamada
/// seguinte falhou. A decisão precisa sobreviver a uma falha em execução.
@Suite("Fallback em tempo de execução")
struct SuggesterComFallbackTests {
    private let reserva = StaticRulesSuggester(roteiro: Fixture.roteiro())

    @Test("Quando o modelo on-device falha, a dica vem das regras estáticas")
    func caiParaAReserva() async throws {
        let suggester = SuggesterComFallback(
            principal: SuggesterQueFalha(erro: .falha("modelo indisponível na prática")),
            reserva: reserva
        )

        let sugestao = try await suggester.suggestTechnique(
            for: Fixture.etapa(itensNecessarios: ["caneta-delineadora"]),
            inventory: Fixture.resumos("lapis-preto")
        )

        #expect(sugestao.origem == .regrasEstaticas)
        #expect(sugestao.dica.contains("Lápis preto"))
    }

    /// Se a estética gótica esbarrar no guardrail da Apple, a trilha continua com
    /// o texto curado em vez de travar na etapa.
    @Test("Guardrail também cai para a reserva")
    func guardrailNaoTrava() async throws {
        let suggester = SuggesterComFallback(
            principal: SuggesterQueFalha(erro: .guardrail),
            reserva: reserva
        )

        let sugestao = try await suggester.suggestTechnique(
            for: Fixture.etapa(itensNecessarios: ["clown"]),
            inventory: Fixture.resumos("base")
        )

        #expect(sugestao.origem == .regrasEstaticas)
    }

    @Test("Com o modelo funcionando, a reserva não é usada")
    func mantemOPrincipal() async throws {
        let esperada = Fixture.sugestao(dica: "Veio do modelo", origem: .onDevice)
        let suggester = SuggesterComFallback(
            principal: SuggesterFalso(resultado: .success(esperada)),
            reserva: reserva
        )

        let sugestao = try await suggester.suggestTechnique(
            for: Fixture.etapa(),
            inventory: Fixture.resumos("lapis-preto")
        )

        #expect(sugestao.origem == .onDevice)
        #expect(sugestao.dica == "Veio do modelo")
    }

    @Test("A mensagem de erro não expõe texto técnico")
    func mensagemHumana() {
        let mensagem = SuggestionError.falha("GenerationError error -1").localizedDescription

        #expect(!mensagem.contains("GenerationError"))
        #expect(!mensagem.contains("error -1"))
    }
}

private struct SuggesterQueFalha: TechniqueSuggesting {
    let erro: SuggestionError

    func suggestTechnique(
        for step: TutorialStep,
        inventory: [ItemResumo]
    ) async throws -> TechniqueSuggestion {
        throw erro
    }
}
