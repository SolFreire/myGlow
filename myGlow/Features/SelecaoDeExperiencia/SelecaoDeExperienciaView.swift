//
//  SelecaoDeExperienciaView.swift
//  myGlow
//

import SwiftUI

/// A escolha da especialista.
///
/// Aparece em dois momentos com o mesmo desenho: no primeiro uso, quando a Edna
/// pergunta qual estilo tentar, e depois sempre que a pessoa senta na cadeira do
/// salão. Ainda sem desenho do design — por enquanto só os três caminhos.
struct SelecaoDeExperienciaView: View {
    /// No primeiro uso ainda não existe salão para onde voltar; a partir da
    /// cadeira, existe.
    var papelDoCanto: PapelDoCanto = .voltarAoSalao
    let aoEscolher: (Subcultura) -> Void

    @Environment(AppEnvironment.self) private var ambiente

    var body: some View {
        TelaEmConstrucao(titulo: "Escolha a experiência", papelDoCanto: papelDoCanto) {
            VStack(spacing: 12) {
                ForEach(Subcultura.allCases) { subcultura in
                    BotaoPrimario(
                        titulo: "\(nome(de: subcultura)), \(subcultura.nome)",
                        preencheLargura: false
                    ) {
                        aoEscolher(subcultura)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func nome(de subcultura: Subcultura) -> String {
        ambiente.roteiro(de: subcultura)?.personagem.nome ?? subcultura.personagem
    }
}
