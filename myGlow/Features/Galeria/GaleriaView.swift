//
//  GaleriaView.swift
//  myGlow
//

import SwiftUI
import SwiftData

struct PinDaSubcultura: View {
    let subcultura: Subcultura

    private var nomeDoAsset: String {
        switch subcultura {
        case .gotica: "pino-polaroid-lucy"
        case .gyaru: "pino-polaroid-sana"
        case .newRomantic: "pino-polaroid-cindy"
        }
    }

    var body: some View {
        Image(nomeDoAsset)
            .resizable()
            .scaledToFit()
            .frame(width: 70, height: 70)
    }
}

struct GaleriaView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.voltarAoSalao) private var voltarAoSalao
    @Query(sort: \FotoSalva.criadaEm, order: .reverse)
    var photos: [FotoSalva]

    var aoAbrirFoto: (FotoSalva) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    var body: some View {
        ZStack {
            Image("fundo-galeria")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: .all)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(photos) { photo in
                        if let uiImage = UIImage(data: photo.dados) {
                            Button {
                                SoundManager.shared.playSoundEffect(named: "botao-efeito")
                                aoAbrirFoto(photo)
                            } label: {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 220)
                                    .overlay(alignment: .top) {
                                        PinDaSubcultura(subcultura: photo.subcultura)
                                            .alignmentGuide(.top) { $0.height / 2 }
                                            .padding(.top)
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.top, 64)
            }
        }
        .navigationBarBackButtonHidden(true)
        
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                BotaoCircular(simbolo: "door.right.hand.open"){
                    SoundManager.shared.playSoundEffect(named: "botao-efeito")
                    voltarAoSalao()
                }
            }
            .sharedBackgroundVisibility(.hidden)

            ToolbarItem(placement: .title) {
                Text("myPhotos")
                    .font(Tipografia.titulo)
                    .foregroundStyle(Color.black)
            }
        }
        
    }
}
