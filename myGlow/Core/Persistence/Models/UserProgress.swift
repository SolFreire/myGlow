//
//  UserProgress.swift
//  myGlow
//

import Foundation
import SwiftData

/// Progresso da pessoa em uma trilha. Um registro por subcultura.
@Model
final class UserProgress {
    var subcultura: Subcultura = Subcultura.gotica
    var etapasConcluidas: [String] = []
    var tutoriaisConcluidos: Int = 0
    var atualizadoEm: Date = Date()

    init(
        subcultura: Subcultura,
        etapasConcluidas: [String] = [],
        tutoriaisConcluidos: Int = 0,
        atualizadoEm: Date = .now
    ) {
        self.subcultura = subcultura
        self.etapasConcluidas = etapasConcluidas
        self.tutoriaisConcluidos = tutoriaisConcluidos
        self.atualizadoEm = atualizadoEm
    }
}
