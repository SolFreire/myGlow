//
//  Tipografia.swift
//  myGlow
//

import SwiftUI

enum Tipografia {

    static let titulo = Font.custom(Fontes.lifeSaversExtraBold, size: 30, relativeTo: .title)
    static let secao = Font.custom(Fontes.lifeSaversBold, size: 22, relativeTo: .title2)
    static let nomeDaPersonagem = Font.custom(Fontes.lifeSaversBold, size: 17, relativeTo: .headline)
    static let botao = Font.system(.title3, design: .rounded, weight: .semibold)

    static let fala = Font.system(.title3, design: .rounded, weight: .regular)
    static let corpo = Font.system(.body, design: .rounded)
    static let legenda = Font.system(.caption, design: .rounded, weight: .medium)
    static let destaqueDoCorpo = Font.system(.headline, design: .rounded)
}
