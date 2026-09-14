//
//  Cores.swift
//  myGlow
//

import SwiftUI
import UIKit


enum Cores {

    static func cor(_ asset: String, padrao: Color) -> Color {
        UIColor(named: asset).map(Color.init) ?? padrao
    }

    static let fundo = Color(red: 0.09, green: 0.07, blue: 0.11)
    static let texto = Color(red: 0.97, green: 0.95, blue: 0.98)
    static let textoSecundario = Color(red: 0.72, green: 0.68, blue: 0.76)
    static let textoDestaque = Color("cor-botão")
    static let destaque = cor("cor-destaque", padrao: Color(red: 0.93, green: 0.36, blue: 0.60))


    static let painelDoCatalogo = Color("cor-painel-catalogo")
    static let cartaoDoCatalogo = Color("cor-cartao-catalogo")
}
