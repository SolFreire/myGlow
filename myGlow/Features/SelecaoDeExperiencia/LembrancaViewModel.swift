//
//  LembrancaViewModel.swift
//  myGlow
//

import Foundation
import Observation

/// Quais lembranças já foram conquistadas.
///
/// É o que decide o que o salão desenha: cada personagem deixa seu objeto na
/// cena quando a trilha dela termina, e antes disso o lugar fica vazio. Ler
/// isso errado ou tarde tira da pessoa a recompensa de ver o salão mudar, por
/// isso a leitura é refeita a cada volta ao salão.
@MainActor
@Observable
final class LembrancaViewModel {
    private(set) var concluidas: Set<Subcultura> = []
    private(set) var erro: String?

    private let progresso: any ProgressRepository

    init(progresso: any ProgressRepository) {
        self.progresso = progresso
    }

    func carregar() async {
        do {
            var concluidas: Set<Subcultura> = []
            for subcultura in Subcultura.allCases
            where try await progresso.progresso(de: subcultura).tutoriaisConcluidos > 0 {
                concluidas.insert(subcultura)
            }
            self.concluidas = concluidas
            erro = nil
        } catch {
            erro = error.localizedDescription
        }
    }

    func desbloqueado(_ subcultura: Subcultura) -> Bool {
        concluidas.contains(subcultura)
    }
}
