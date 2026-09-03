//
//  Arte.swift
//  myGlow
//

import SwiftUI
import UIKit


enum Arte {
    static func existe(_ nome: String) -> Bool {
        guard UIColor(named: nome) == nil else { return false }
        return UIImage(named: nome) != nil
    }


    static func proporcao(_ nome: String) -> CGFloat? {
        guard existe(nome), let imagem = UIImage(named: nome), imagem.size.height > 0 else { return nil }
        return imagem.size.width / imagem.size.height
    }
}

struct ArteView: View {
    let nome: String
    var simbolo = "photo"
    var cor: Color = Provisorio.destaque

    var body: some View {
        if Arte.existe(nome) {
            Image(nome)
                .resizable()
                .scaledToFit()
                .accessibilityHidden(true)
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: Provisorio.cantoDoCartao, style: .continuous)
            .fill(cor.opacity(0.18))
            .overlay {
                Image(systemName: simbolo)
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(cor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: Provisorio.cantoDoCartao, style: .continuous)
                    .strokeBorder(cor.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            }
            .accessibilityHidden(true)
    }
}

