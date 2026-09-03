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
        case .gotica: "Sobre góticos"
        case .gyaru: "Sobre gyarus"
        case .newRomantic: "Sobre new romantics"
        }
    }
}
