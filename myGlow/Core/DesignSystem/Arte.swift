//
//  Arte.swift
//  myGlow
//

import SwiftUI
import UIKit


enum DescricaoDeArte {
    static let tabela = "Acessibilidade"

    static func chave(de asset: String) -> String { "arte.\(asset)" }

    static func para(_ asset: String) -> String? {
        let chave = chave(de: asset)
        let texto = NSLocalizedString(chave, tableName: tabela, comment: "")
        return texto == chave ? nil : texto
    }
}

extension View {
    func descricaoDaArte(_ asset: String) -> some View {
        modifier(DescricaoDaArte(asset: asset))
    }
}

private struct DescricaoDaArte: ViewModifier {
    let asset: String

    func body(content: Content) -> some View {
        if let descricao = DescricaoDeArte.para(asset) {
            content.accessibilityLabel(descricao)
        } else {
            content.accessibilityHidden(true)
        }
    }
}


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
    var cor: Color = Cores.destaque

    private let cantoDoCartao: CGFloat = 20

    var body: some View {
        if Arte.existe(nome) {
            Image(nome)
                .resizable()
                .scaledToFit()
                .descricaoDaArte(nome)
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        RoundedRectangle(cornerRadius: cantoDoCartao, style: .continuous)
            .fill(cor.opacity(0.18))
            .overlay {
                Image(systemName: simbolo)
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(cor)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cantoDoCartao, style: .continuous)
                    .strokeBorder(cor.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
            }
            .accessibilityHidden(true)
    }
}

