//
//  LimiteDaDica.swift
//  myGlow
//

import Foundation


nonisolated enum LimiteDaDica {
    static let caracteres = 260

    static func aplicar(_ texto: String) -> String {
        guard texto.count > caracteres else { return texto }
        let cortada = String(texto.prefix(caracteres))
        if let fimDeFrase = cortada.range(of: ".", options: .backwards) {
            return String(cortada[..<fimDeFrase.upperBound])
        }
        if let fimDePalavra = cortada.range(of: " ", options: .backwards) {
            return String(cortada[..<fimDePalavra.lowerBound]) + "…"
        }
        return cortada + "…"
    }
}
