//
//  Provisorio.swift
//  myGlow
//

import SwiftUI
import UIKit

/// O que existe só enquanto falta arte ou definição de design.
///
/// **Este arquivo é para ser apagado.** Cada valor aqui é um remendo com prazo:
/// ou vira um Color Set no catálogo, ou some junto com a tela provisória que o
/// usa. Nada que o design já entregou deve morar aqui — cor definitiva vai para
/// `Paleta`, medida de componente vai para o próprio componente.
///
/// O que ainda depende disto:
/// - `TelaEmConstrucao`, e as telas sem desenho que a usam (Seleção de
///   experiência, Câmera, Galeria, Lembrança)
/// - `FundoSalao` e o placeholder do `ArteView`, enquanto houver cenário sem arte
/// - O painel da tela de Cadastro, até virar Color Set
/// - A cor por subcultura, inventada aqui e nunca definida pelo design
enum Provisorio {
    /// Lê a cor do catálogo quando o Color Set existe, e cai no valor de código
    /// quando não. É a própria existência deste `padrao` que torna o valor
    /// provisório.
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
