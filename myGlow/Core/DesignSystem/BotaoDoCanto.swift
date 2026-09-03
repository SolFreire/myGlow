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

    @Environment(\.voltarAoSalao) private var voltarAoSalao

    var body: some View {
        switch papel {
        case .ajustes:
            BotaoAjustes()

        case .voltarAoSalao:
            BotaoCircular(simbolo: "door.right.hand.open", acao: voltarAoSalao)
                .accessibilityLabel("Voltar ao salão")
        }
    }
}

extension EnvironmentValues {
    /// Volta ao salão de qualquer ponto da pilha de navegação.
    ///
    /// Vive no ambiente, e não como parâmetro de cada tela: são seis telas com o
    /// mesmo botão, e passar a closure por todas as assinaturas só criaria
    /// ruído. Quem monta a pilha é quem sabe como desmontá-la.
    @Entry var voltarAoSalao: () -> Void = {}
}
