//
//  AppRoute.swift
//  myGlow
//

import Foundation

enum AppRoute: Hashable {
    case cadastro
    case selecaoDeExperiencia
    case lembranca(Subcultura)
    case tutorial(Subcultura)
    case camera(Subcultura)
    case galeria
}

#if DEBUG
extension AppRoute {

    static var pularTelaInicial: Bool {
        UserDefaults.standard.bool(forKey: "pularTelaInicial")
    }

    static var caminhoDeLancamento: [AppRoute] {
        guard let valor = UserDefaults.standard.string(forKey: "telaInicial") else { return [] }

        let partes = valor.split(separator: ":", maxSplits: 1).map(String.init)
        let subcultura = partes.count > 1 ? Subcultura(rawValue: partes[1]) : nil

        switch partes[0] {
        case "cadastro": return [.cadastro]
        case "galeria": return [.galeria]
        case "tutorial": return [.tutorial(subcultura ?? .gotica)]
        case "camera": return [.camera(subcultura ?? .gotica)]
        default: return []
        }
    }
}
#endif
