//
//  SalvarFotoView.swift
//  myGlow
//
//  Created by marquiros on 03/09/26.
//

import SwiftUI
import SwiftData

struct SalvarFotoView: View {
    let subcultura: Subcultura
    let aoConcluir: () -> Void

    @Environment(CameraModel.self) var model: CameraModel
    @Environment(\.displayScale) var displayScale
    @Environment(\.modelContext) private var modelContext

    @State private var saved = false
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            ZStack {
                Image("fundo-salvar-foto")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea(edges: .all)

                HStack {
                    polaroid
                        .rotationEffect(.degrees(-4.08))
                        .padding(.top, 48)
                    BalaoDeFala(
                        texto: "Uau! Você arrasou! Deseja salvar a foto pra mostrar o quanto ficou incrível?",
                        rotulo: subcultura.personagem
                    )
                    .frame(maxWidth: width * 0.45)
                    .overlay(alignment: .bottomTrailing) {
                        buttonsView()
                            .alignmentGuide(.bottom) { $0.height / 2 }
                    }
                    .padding()
                }
            }
            .frame(maxWidth: width, maxHeight: height)
        }
        .ignoresSafeArea(edges: .all)

        .overlay(alignment: .topLeading) {
            BotaoCircular(simbolo: "door.right.hand.open", acao: savePhotoAndDismiss)
                .padding(20)
        }
        .navigationBarBackButtonHidden(true)
    }
    private func buttonsView() -> some View {
        HStack {
            BotaoPrimario(titulo: "Refazer", simbolo: "arrow.trianglehead.counterclockwise", preencheLargura: false){
                SoundManager.shared.playSoundEffect(named: "botao-efeito")
                model.clearPhoto()
            }
            ShareLink(item: renderedPolaroidPng, preview: SharePreview(Text("Polaroid"), image: renderedPolaroidPng)) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Exportar")
                }
            }
            .font(Tipografia.destaqueDoCorpo)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(maxWidth: nil)
            .background(Paleta.botao.gradiente, in: Capsule())
        }
        .padding()
    }
    
    var polaroid: some View {
        PolaroidCard(image: model.photoToken?.image)
    }
    
    var renderedPolaroidData: Data? {
        let renderer = ImageRenderer(content: polaroid)
        renderer.scale = displayScale
        return renderer.uiImage?.pngData()
    }
    
    var renderedPolaroidPng: Image {
        let renderer = ImageRenderer(content: polaroid)
        renderer.scale = displayScale
        
        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
                .resizable()
        }
        return Image("Doll1")
    }
    
    private func savePhotoAndDismiss() {
        guard let photo = renderedPolaroidData else { return }
        
        let foto = FotoSalva(subcultura: subcultura, dados: photo)
        modelContext.insert(foto)
        
        model.clearPhoto()
        aoConcluir()
    }
    
}

#Preview {
    @Previewable @State var model = CameraModel()
    SalvarFotoView(subcultura: .gotica, aoConcluir: {})
        .environment(model)
}
