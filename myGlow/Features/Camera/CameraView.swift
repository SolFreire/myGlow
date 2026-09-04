//
//  CameraView.swift
//  myGlow
//

//import SwiftUI
//
//struct CameraView: View {
//    let subcultura: Subcultura
//    let aoConcluir: () -> Void
//
//    var body: some View {
//        TelaEmConstrucao(titulo: "Registrar o visual") {
//            BotaoPrimario(titulo: "Continuar", simbolo: "arrow.right", preencheLargura: false, simboloAoFim: true) {
//                aoConcluir()
//            }
//        }
//        .toolbar(.hidden, for: .navigationBar)
//    }
//}

//
//  CameraView.swift
//  myGlow
//

import SwiftUI

struct CameraView: View {
    let subcultura: Subcultura
    let aoConcluir: () -> Void
    
    @State private var model = CameraModel()
    
    var body: some View {
        Group {
            if model.photoToken != nil {
                SalvarFotoView(subcultura: subcultura, aoConcluir: aoConcluir)
            } else {
                CameraPreview()
                    .onAppear {
                        model.resumePreview()
                    }
                    .onDisappear {
                        model.pausePreview()
                    }
            }
        }
        .environment(model)
        .task {
            await model.startCamera()
        }
        .onDisappear {
            model.stopCamera()
        }
    }
}
