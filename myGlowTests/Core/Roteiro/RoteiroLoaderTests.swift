//
//  RoteiroLoaderTests.swift
//  myGlowTests
//

import Testing
@testable import myGlow

/// O roteiro é editado em JSON por quem escreve o conteúdo, não em Swift.
/// Estes testes são o que impede uma edição quebrada de passar despercebida.
@Suite("Roteiros do bundle")
struct RoteiroLoaderTests {
    @Test("As três trilhas decodificam", arguments: Subcultura.allCases)
    func decodifica(_ subcultura: Subcultura) throws {
        let roteiro = try RoteiroLoader.carregar(subcultura)

        #expect(roteiro.subcultura == subcultura)
        #expect(!roteiro.etapas.isEmpty)
        #expect(!roteiro.briefing.isEmpty)
        #expect(!roteiro.personagem.nome.isEmpty)
        #expect(!roteiro.personagem.personalidade.isEmpty)
    }

    @Test("O fluxo de primeiro uso decodifica e alterna fala e tela")
    func onboardingDecodifica() throws {
        let onboarding = try RoteiroLoader.carregarOnboarding()

        #expect(onboarding.personagem.nome == "Edna")

        let telas = onboarding.passos.compactMap(\.tela)
        #expect(telas == [.cadastro, .salao], "A Edna manda cadastrar a maleta antes de escolher a experiência")

        for passo in onboarding.passos where passo.tipo == .fala {
            #expect(passo.falas?.isEmpty == false)
        }
    }

    @Test("Toda etapa tem ao menos uma fala", arguments: Subcultura.allCases)
    func etapasTemFalas(_ subcultura: Subcultura) throws {
        for etapa in try RoteiroLoader.carregar(subcultura).etapas {
            #expect(!etapa.falas.isEmpty, "Etapa \(etapa.id) ficou sem fala")
            #expect(!etapa.titulo.isEmpty)
        }
    }

    @Test("Ids de etapa não se repetem dentro de uma trilha", arguments: Subcultura.allCases)
    func idsUnicos(_ subcultura: Subcultura) throws {
        let ids = try RoteiroLoader.carregar(subcultura).etapas.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    /// O roteiro cita produtos por id do catálogo. Se alguém escrever
    /// "sombra-cinza" num JSON, a etapa pediria um item que não existe e a
    /// sugestão de técnica nunca dispararia — este teste pega isso.
    @Test("Todo item citado existe no catálogo", arguments: Subcultura.allCases)
    func itensExistemNoCatalogo(_ subcultura: Subcultura) throws {
        for etapa in try RoteiroLoader.carregar(subcultura).etapas {
            for id in etapa.itensNecessarios {
                #expect(
                    CatalogoMaquiagem.item(id: id) != nil,
                    "Etapa \(etapa.id) pede \"\(id)\", que não está no catálogo"
                )
            }
        }
    }

    /// A ilustração acompanha a fala: é ela que mostra a maquiagem avançando no
    /// rosto. Uma fala sem arte deixaria a personagem congelada no meio do passo.
    @Test("Toda fala tem a sua ilustração", arguments: Subcultura.allCases)
    func umaIlustracaoPorFala(_ subcultura: Subcultura) throws {
        for etapa in try RoteiroLoader.carregar(subcultura).etapas {
            #expect(
                etapa.ilustracoes.count == etapa.falas.count,
                "Etapa \(etapa.id): \(etapa.ilustracoes.count) ilustrações para \(etapa.falas.count) falas"
            )
        }
    }

    /// A arte da Lucy já foi entregue: se um nome for renomeado no catálogo e
    /// não no roteiro, a trilha dela volta a desenhar placeholder em silêncio.
    @Test("A trilha da Lucy tem toda a arte no catálogo")
    @MainActor
    func arteDaLucyExiste() throws {
        for etapa in try RoteiroLoader.carregar(.gotica).etapas {
            for nome in etapa.ilustracoes {
                #expect(Arte.existe(nome), "Falta \"\(nome)\" no catálogo (etapa \(etapa.id))")
            }
        }
    }

    @Test("Cada trilha abre e fecha", arguments: Subcultura.allCases)
    func temAberturaEFechamento(_ subcultura: Subcultura) throws {
        let etapas = try RoteiroLoader.carregar(subcultura).etapas

        #expect(etapas.first?.tipo == .abertura)
        #expect(etapas.last?.tipo == .fechamento, "É o fechamento que convida para a foto")
    }

    @Test("Os produtos declarados pela personagem existem no catálogo", arguments: Subcultura.allCases)
    func produtosDaPersonagemExistem(_ subcultura: Subcultura) throws {
        for id in try RoteiroLoader.carregar(subcultura).personagem.produtos {
            #expect(CatalogoMaquiagem.item(id: id) != nil, "Produto \"\(id)\" não está no catálogo")
        }
    }
}
