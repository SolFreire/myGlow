//
//  Provisorio.swift
//  myGlow
//

import SwiftUI
import UIKit


enum Provisorio {

    static func cor(_ asset: String, padrao: Color) -> Color {
        UIColor(named: asset).map(Color.init) ?? padrao
    }

    static let fundo = Color(red: 0.09, green: 0.07, blue: 0.11)
    static let texto = Color(red: 0.97, green: 0.95, blue: 0.98)
    static let textoSecundario = Color(red: 0.72, green: 0.68, blue: 0.76)
    static let destaque = cor("cor-destaque", padrao: Color(red: 0.93, green: 0.36, blue: 0.60))

    /// Azuis do painel de itens, na tela de Cadastro.
    static let painelDoCatalogo = cor("cor-painel-catalogo", padrao: Color(red: 0.72, green: 0.87, blue: 0.97))
    static let cartaoDoCatalogo = cor("cor-cartao-catalogo", padrao: Color(red: 0.82, green: 0.92, blue: 0.99))

    /// Raio dos cartões do placeholder de arte.
    static let cantoDoCartao: CGFloat = 20

    static func cor(de subcultura: Subcultura) -> Color {
        switch subcultura {
        case .gotica: Color(red: 0.55, green: 0.30, blue: 0.72)
        case .gyaru: Color(red: 0.98, green: 0.60, blue: 0.25)
        case .newRomantic: Color(red: 0.30, green: 0.52, blue: 0.95)
        }
    }
}
