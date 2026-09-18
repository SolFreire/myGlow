//
//  GuiaDeRolagem.swift
//  myGlow
//

import SwiftUI



struct EstadoDeRolagem: Equatable {
    var deslocamento: CGFloat = 0
    var alturaDoConteudo: CGFloat = 0
    var alturaVisivel: CGFloat = 0

    
    var fracaoVisivel: CGFloat {
        guard alturaDoConteudo > 0 else { return 1 }
        return min(1, alturaVisivel / alturaDoConteudo)
    }

    
    var progresso: CGFloat {
        let percurso = alturaDoConteudo - alturaVisivel
        guard percurso > 0 else { return 0 }
        return min(1, max(0, deslocamento / percurso))
    }

    var precisaDeGuia: Bool {
        alturaDoConteudo > alturaVisivel + 1
    }
}


struct GuiaDeRolagem: View {
    let estado: EstadoDeRolagem
    @Binding var posicao: ScrollPosition
    var largura: CGFloat = 14
    var cor: Color = Paleta.botao.base

    @State private var arrastando = false

    var body: some View {
        GeometryReader { proxy in
            let alturaDaTrilha = proxy.size.height
            let alturaDoPolegar = max(32, alturaDaTrilha * estado.fracaoVisivel)
            let percurso = max(alturaDaTrilha - alturaDoPolegar, 0)

            ZStack(alignment: .top) {
                Capsule()
                    .fill(Color.white.opacity(0.28))

                Capsule()
                    .fill(cor)
                    .frame(height: alturaDoPolegar)
                    .offset(y: percurso * estado.progresso)
                    .scaleEffect(arrastando ? 1.12 : 1)
                    .animation(.easeOut(duration: 0.12), value: arrastando)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { valor in
                        arrastando = true
                        let alcance = estado.alturaDoConteudo - estado.alturaVisivel
                        guard alcance > 0, alturaDaTrilha > 0 else { return }
                        let fracao = min(1, max(0, valor.location.y / alturaDaTrilha))
                        posicao.scrollTo(y: fracao * alcance)
                    }
                    .onEnded { _ in arrastando = false }
            )
        }
        .frame(width: largura)
        .opacity(estado.precisaDeGuia ? 1 : 0)
        .allowsHitTesting(estado.precisaDeGuia)
        .animation(.easeOut(duration: 0.15), value: estado.precisaDeGuia)
    }
}
