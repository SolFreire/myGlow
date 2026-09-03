//
//  Fontes.swift
//  myGlow
//

import CoreText
import Foundation
import SwiftUI


enum Fontes {
    static let lifeSaversRegular = "LifeSavers-Regular"
    static let lifeSaversBold = "LifeSavers-Bold"
    static let lifeSaversExtraBold = "LifeSavers-ExtraBold"

    private static let arquivos = [lifeSaversRegular, lifeSaversBold, lifeSaversExtraBold]


    static func registrar() {
        for nome in arquivos {
            guard let url = Bundle.main.url(forResource: nome, withExtension: "ttf") else {
                assertionFailure("Fonte \(nome).ttf não está no bundle")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    static var disponiveis: [String] {
        arquivos.filter { UIFont(name: $0, size: 12) != nil }
    }
}
