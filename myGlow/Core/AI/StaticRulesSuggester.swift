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
            let itemUsado = CatalogoMaquiagem.nome(paraID: par.regra.substituto)
            dica = "Sem \(CatalogoMaquiagem.nome(paraID: par.ausente))? Use \(itemUsado): \(par.regra.comoFazer)"
        default:
            let clausulas = aplicaveis.map {
                "sem \(CatalogoMaquiagem.nome(paraID: $0.ausente)), use \(CatalogoMaquiagem.nome(paraID: $0.regra.substituto))"
            }
            dica = "Faltando mais de um item: " + clausulas.joined(separator: "; ") + "."
        }

        return TechniqueSuggestion(dica: LimiteDaDica.aplicar(dica), origem: .regrasEstaticas)
    }
}
