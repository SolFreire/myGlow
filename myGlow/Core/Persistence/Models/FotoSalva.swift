//
//  FotoSalva.swift
//  myGlow
//

import Foundation
import SwiftData


@Model
final class FotoSalva {
    var subcultura: Subcultura = Subcultura.gotica
    var criadaEm: Date = Date()

    @Attribute(.externalStorage)
    var dados: Data = Data()

    init(subcultura: Subcultura, dados: Data, criadaEm: Date = .now) {
        self.subcultura = subcultura
        self.dados = dados
        self.criadaEm = criadaEm
    }
}
