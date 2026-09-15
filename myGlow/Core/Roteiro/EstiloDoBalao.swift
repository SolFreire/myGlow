//
//  EstiloDoBalao.swift
//  myGlow
//

import Foundation


extension Fala.Tipo {
    var estiloDoBalao: BalaoDeFala.Estilo {
        switch self {
        case .introducao, .fechamentoIntro, .fechamento, .contexto:
            .padrao
        case .instrucaoPratica, .instrucaoPraticaTecnica:
            .passo
        case .contextoHistorico, .discussao:
            .contexto
        }
    }
}

extension Subcultura {
    var rotuloDeContexto: String {
        switch self {
        case .gotica: String(localized: "Sobre góticos")
        case .gyaru: String(localized: "Sobre gyarus")
        case .newRomantic: String(localized: "Sobre new romantics")
        }
    }
}
