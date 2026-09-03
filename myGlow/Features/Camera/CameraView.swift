//
//  CameraView.swift
//  myGlow
//

import SwiftUI

struct CameraView: View {
    let subcultura: Subcultura
    let aoConcluir: () -> Void

    var body: some View {
        TelaEmConstrucao(titulo: "Registrar o visual") {
            BotaoPrimario(titulo: "Continuar", simbolo: "arrow.right", preencheLargura: false, simboloAoFim: true) {
                aoConcluir()
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
