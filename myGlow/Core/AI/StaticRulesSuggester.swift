//
//  StaticRulesSuggester.swift
//  myGlow
//

import Foundation


nonisolated struct StaticRulesSuggester: TechniqueSuggesting {
    let roteiro: Roteiro

    func suggestTechnique(
        for step: TutorialStep,
        inventory: [ItemResumo]
    ) async throws -> TechniqueSuggestion {
        let idsNaMaleta = Set(inventory.map(\.id))
        let faltantes = step.itensFaltantes(naMaleta: idsNaMaleta)
        let aplicaveis = SubstituicoesCuradas.aplicaveis(faltantes: faltantes, idsNaMaleta: idsNaMaleta)

        let dica: String
        switch aplicaveis.count {
        case 0:
            dica = SubstituicoesCuradas.semSubstituto
        case 1:
            let par = aplicaveis[0]
            let itemFaltante = CatalogoMaquiagem.nome(paraID: par.ausente)
            let itemUsado = CatalogoMaquiagem.nome(paraID: par.regra.substituto)
            dica = "\(String(localized: "Sem")) \(itemFaltante)? \(String(localized: "Use")) \(itemUsado): \(par.regra.comoFazer)"
        default:
            // Cada cláusula é sua própria frase — "Sem X? Use Y." — pra reaproveitar
            // "Sem"/"Use" sempre com a mesma capitalização (frase nova a cada vez).
            // Já tentei uma variante minúscula só pra esse caso ("sem X, use Y; ..."),
            // mas duas chaves que só diferem na capitalização colidem no símbolo
            // gerado pelo String Catalog — e o resultado também lia mal, com "Sem"
            // maiúsculo no meio da frase. Isso também ajuda o corte de
            // `LimiteDaDica`: com um ponto por cláusula, ele sempre encontra onde
            // cortar sem quebrar uma cláusula ao meio.
            let clausulas = aplicaveis.map {
                "\(String(localized: "Sem")) \(CatalogoMaquiagem.nome(paraID: $0.ausente))? \(String(localized: "Use")) \(CatalogoMaquiagem.nome(paraID: $0.regra.substituto))."
            }
            dica = String(localized: "Faltando mais de um item:") + " " + clausulas.joined(separator: " ")
        }

        return TechniqueSuggestion(dica: LimiteDaDica.aplicar(dica), origem: .regrasEstaticas)
    }
}
