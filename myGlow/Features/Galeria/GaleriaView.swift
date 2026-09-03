//
//  GaleriaView.swift
//  myGlow
//

import SwiftUI

/// O álbum das fotos salvas. Sem desenho do design ainda.
///
/// O `FotoRepository` por trás já guarda e lista as fotos, com testes.
struct GaleriaView: View {
    var body: some View {
        TelaEmConstrucao(titulo: "Meu álbum") { EmptyView() }
            .toolbar(.hidden, for: .navigationBar)
    }
}
