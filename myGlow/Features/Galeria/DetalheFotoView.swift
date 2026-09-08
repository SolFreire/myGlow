//
//  DetalheFotoView.swift
//  myGlow
//
//  Created by marquiros on 06/09/26.
//

import SwiftUI
import SwiftData

struct DetalheFotoView: View {
    @Environment(\.modelContext) var modelContext
    let foto: FotoSalva
    let aoVoltar: () -> Void
    @State var showAlert: Bool = false
    
    var body: some View {
        ZStack {
            Image("fundo-salvar-foto")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea(edges: .all)
            
            HStack(spacing: 24) {
                if let uiImage = UIImage(data: foto.dados) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                }
                buttonsView()
            }
            .navigationBarBackButtonHidden(true)
            
            .toolbar {
                ToolbarItem(placement: .topBarLeading){
                    BotaoCircular(simbolo: "door.right.hand.open"){
                        SoundManager.shared.playSoundEffect(named: "botao-efeito")
                        aoVoltar()
                    }
                }
                .sharedBackgroundVisibility(.hidden)
            }
            .alert("Tem certeza de que deseja excluir a foto?", isPresented: $showAlert) {
                Button("Cancelar", role: .cancel) {}
                Button("Excluir", role: .destructive) {
                    SoundManager.shared.playSoundEffect(named: "botao-efeito")
                    modelContext.delete(foto)
                    aoVoltar()
                }
            } message: {
                Text("Essa ação não pode ser desfeita.")
            }
        }
    }
    private func buttonsView() -> some View {
        HStack {
            ShareLink(item: renderedPolaroid, preview: SharePreview(Text("Polaroid"), image: renderedPolaroid)) {
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
            
            BotaoPrimario(titulo: "Deletar", simbolo: "trash", cores: Paleta.botaoDeletarFoto, preencheLargura: false) {
                SoundManager.shared.playSoundEffect(named: "botao-efeito")
                showAlert = true
            }
        }
        .padding()
    }
    
    private var polaroidImage: UIImage? {
        UIImage(data: foto.dados)
    }
    
    private var renderedPolaroid: Image {
        if let polaroidImage {
            Image(uiImage: polaroidImage)
                .resizable()
        } else {
            Image("Doll1")
        }
    }
    
}
