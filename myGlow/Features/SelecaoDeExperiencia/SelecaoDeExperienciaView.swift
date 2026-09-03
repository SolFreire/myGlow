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

/// A lembrança que cada trilha deixa no salão. Sem desenho ainda.
///
/// Chega-se aqui tocando o objeto no salão, e o objeto só está lá quando a
/// trilha terminou — então na prática esta tela só abre desbloqueada. A outra
/// mensagem fica como rede: se algum dia houver outra porta de entrada (um
/// atalho de DEBUG, uma lista de conquistas), ela não abre mentindo.
struct LembrancaView: View {
    let subcultura: Subcultura
    let desbloqueado: Bool

    var body: some View {
        TelaEmConstrucao(titulo: "Lembrança de \(subcultura.personagem)") {
            Text(
                desbloqueado
                    ? "Você já concluiu a experiência com \(subcultura.personagem)."
                    : "Conclua a experiência com \(subcultura.personagem) para desbloquear."
            )
            .font(Tipografia.corpo)
            .foregroundStyle(Provisorio.textoSecundario)
            .multilineTextAlignment(.center)
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}
