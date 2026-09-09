//
//  BotaoDoCanto.swift
//  myGlow
//

import SwiftUI


enum PapelDoCanto {
    case ajustes
    case voltarAoSalao
}

struct BotaoDoCanto: View {
    
    let papel: PapelDoCanto
    

    var body: some View {
        switch papel {
        case .ajustes:
            BotaoAjustes()

        case .voltarAoSalao:
            BotaoVoltar()
        }
    }
}


