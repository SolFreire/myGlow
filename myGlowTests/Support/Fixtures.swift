//
//  Fixtures.swift
//  myGlowTests
//

import Foundation
@testable import myGlow

enum Fixture {
    static func fala(_ tipo: Fala.Tipo = .instrucaoPratica, _ texto: String = "Aplique com a esponja.") -> Fala {
        Fala(tipo: tipo, texto: texto)
    }

    static func etapa(
        id: String = "etapa-teste",
        titulo: String = "Delineado",
        tipo: TutorialStep.Tipo = .passo,
        itensNecessarios: [String] = ["caneta-delineadora"],
        falas: [Fala] = [fala()]
    ) -> TutorialStep {
        TutorialStep(
            id: id,
            titulo: titulo,
            tipo: tipo,
            itensNecessarios: itensNecessarios,
            ilustracoes: [],
            falas: falas,
            nota: nil
        )
    }

    static func roteiro(
        subcultura: Subcultura = .gotica,
        etapas: [TutorialStep] = [etapa()]
    ) -> Roteiro {
        Roteiro(
            subcultura: subcultura,
            briefing: "Briefing de teste.",
            personagem: RoteiroPersonagem(
                nome: "Lucy",
                aparencia: "Aparência de teste.",
                personalidade: "Personalidade de teste.",
                produtos: ["clown"]
            ),
            etapas: etapas
        )
    }

    static func sugestao(
        passos: [String] = ["Passo de teste"],
        substituicoes: [TechniqueSuggestion.Substituicao] = [],
        origem: TechniqueSuggestion.Origem = .regrasEstaticas
    ) -> TechniqueSuggestion {
        TechniqueSuggestion(
            passos: passos,
            substituicoes: substituicoes,
            itensNaoUtilizados: [],
            curiosidade: "Curiosidade de teste",
            itensForaDaMaleta: [],
            origem: origem
        )
    }

    static func resumos(_ ids: String...) -> [ItemResumo] {
        ids.compactMap { id in
            CatalogoMaquiagem.item(id: id).map {
                ItemResumo(id: $0.id, nome: $0.nome, categoria: $0.categoria.nome)
            }
        }
    }
}
