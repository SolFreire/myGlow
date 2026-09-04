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
        ZStack {
            Image("fundo-salvar-foto")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: .all)
            
            HStack  {
                polaroid
                    .rotationEffect(.degrees(-4.08))
                buttonsView()
            }
        }
        .toolbar {
            ToolbarItem (placement: .navigationBarLeading) {
                Button {
                    savePhotoAndDismiss()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .foregroundStyle(.white)
                }
                .foregroundStyle(.white)
                .buttonStyle(.glassProminent)
                .tint(.corBotaoCamera)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func buttonsView() -> some View {
        HStack {
            Button {
                model.clearPhoto()
            } label: {
                HStack {
                    Image(systemName: "arrow.trianglehead.counterclockwise")
                    Text("Refazer")
                }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .padding(12)
            }
            .padding()
            .buttonStyle(.glass)
            ShareLink(item: renderedPolaroidPng, preview: SharePreview(Text("Polaroid"), image: renderedPolaroidPng)) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Exportar")
                }
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .padding()
            }
            .foregroundStyle(Color.white)
            .buttonStyle(.glass)
        }
        .alert(
            "Fotos salvas!",
            isPresented: $saved
        ) {
            Button("OK", role: .cancel) {
                model.clearPhoto()
                aoConcluir()
            }
        } message: {
            Text("A foto foi adicionada à sua galeria.")
        }
        .padding()
        .font(.system(size: 24, weight: .bold))
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
