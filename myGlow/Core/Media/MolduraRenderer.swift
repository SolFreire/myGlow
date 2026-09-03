//
//  MolduraRenderer.swift
//  myGlow
//

import SwiftUI
import UIKit


@MainActor
enum MolduraRenderer {
    static let lado: CGFloat = 1080

    static func nomeDoAsset(para subcultura: Subcultura) -> String {
        "moldura-\(subcultura.rawValue)"
    }

    static func compor(foto dados: Data, subcultura: Subcultura) -> Data? {
        guard let imagem = UIImage(data: dados) else { return nil }

        let renderer = ImageRenderer(content: Composicao(imagem: imagem, subcultura: subcultura))
        renderer.scale = 1
        renderer.proposedSize = ProposedViewSize(width: lado, height: lado)

        return renderer.uiImage?.jpegData(compressionQuality: 0.9)
    }

    struct Composicao: View {
        let imagem: UIImage
        let subcultura: Subcultura

        var body: some View {
            ZStack {
                Image(uiImage: imagem)
                    .resizable()
                    .scaledToFill()

                moldura
            }
            .frame(width: MolduraRenderer.lado, height: MolduraRenderer.lado)
            .clipped()
        }


        @ViewBuilder
        private var moldura: some View {
            let nome = MolduraRenderer.nomeDoAsset(para: subcultura)

            if Arte.existe(nome) {
                Image(nome)
                    .resizable()
                    .scaledToFill()
            } else {
                VStack {
                    Spacer()
                    Text("myGlow · \(subcultura.nome)")
                        .font(.system(size: 40, weight: .semibold, design: .serif))
                        .foregroundStyle(.white)
                        .padding(.bottom, 44)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    LinearGradient(
                        colors: [.clear, .clear, Provisorio.cor(de: subcultura).opacity(0.75)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay {
                    Rectangle()
                        .strokeBorder(Provisorio.cor(de: subcultura), lineWidth: 24)
                }
            }
        }
    }
}
