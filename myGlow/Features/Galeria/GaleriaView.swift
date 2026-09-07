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
    
    /// "Visual gótico, 3 de setembro" — a trilha e a data, que e como a pessoa
    /// se lembra de qual foto e qual.
    private static func rotulo(de foto: FotoSalva) -> String {
        let data = foto.criadaEm.formatted(.dateTime.day().month(.wide))
        return "Visual \(foto.subcultura.nome.lowercased()), \(data)"
    }

    var body: some View {
        ZStack {
            Image("fundo-galeria")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(edges: .all)
                .descricaoDaArte("fundo-galeria")
            
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
                                // Sem isto o VoiceOver anuncia "imagem" uma vez
                                // por foto, e nao ha como distinguir uma da
                                // outra. A trilha e a data sao o que a pessoa
                                // usaria para se lembrar de qual e qual.
                                .accessibilityElement()
                                .accessibilityLabel(Self.rotulo(de: photo))
                                .accessibilityAddTraits(.isImage)
                                // O excluir vive no menu de contexto, que o
                                // VoiceOver so alcanca pelo rotor. Como acao
                                // nomeada ele fica a um gesto de distancia.
                                .accessibilityAction(named: "Excluir") {
                                    modelContext.delete(photo)
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
