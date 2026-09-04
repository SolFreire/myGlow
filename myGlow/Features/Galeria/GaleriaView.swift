//
//  GaleriaView.swift
//  myGlow
//

import SwiftUI
import SwiftData

/// O álbum das fotos salvas. Sem desenho do design ainda.
///
/// O `FotoRepository` por trás já guarda e lista as fotos, com testes.

struct GaleriaView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FotoSalva.criadaEm, order: .reverse)
    var photos: [FotoSalva]
    
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
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 220)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        modelContext.delete(photo)
                                    } label: {
                                        Label("Excluir", systemImage: "trash")
                                    }
                                }
                            
                        }
                    }
                }
                .padding()
            }
        }
        .toolbar {
            ToolbarItem(placement: .title) {
                Text("myPhotos")
                    .font(Tipografia.titulo)
                    .foregroundStyle(Color.black)
            }
        }
    }
}


#Preview {
    GaleriaView()
        .modelContainer(for: FotoSalva.self)
}
