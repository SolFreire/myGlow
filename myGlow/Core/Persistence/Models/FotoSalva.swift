//
//  FotoSalva.swift
//  myGlow
//

import Foundation
import SwiftData

/// Uma foto do visual finalizado, já achatada com a moldura da subcultura.
///
/// `.externalStorage` mantém os bytes da imagem fora do banco: o SwiftData
/// guarda só a referência, e a Galeria não carrega megabytes ao listar.
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
