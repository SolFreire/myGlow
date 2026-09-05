
//
//  Componentes.swift
//  myGlow
//

import SwiftUI

struct BotaoPrimario: View {
    let titulo: String
    var simbolo: String?
    var tamanho: Tamanho = .padrao
    var preencheLargura = true
    var simboloAoFim = false
    let acao: () -> Void

    enum Tamanho {
        case padrao
        case grande

        var fonte: Font {
            switch self {
            case .padrao: Tipografia.destaqueDoCorpo
            case .grande: Tipografia.botao
            }
        }

        var recuoVertical: CGFloat {
            switch self {
            case .padrao: 14
            case .grande: 20
            }
        }

        var recuoHorizontal: CGFloat {
            switch self {
            case .padrao: 24
            case .grande: 56
            }
        }
    }

    var body: some View {
        Button(action: acao) {
            HStack(spacing: 8) {
                if let simbolo, !simboloAoFim {
                    Image(systemName: simbolo)
                }
                Text(titulo)
                if let simbolo, simboloAoFim {
                    Image(systemName: simbolo)
                }
            }
            .font(tamanho.fonte)
            .foregroundStyle(.white)
            .padding(.horizontal, tamanho.recuoHorizontal)
            .padding(.vertical, tamanho.recuoVertical)
            .frame(maxWidth: preencheLargura ? .infinity : nil)
            .background(Paleta.botao.gradiente, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct CardMaqueadora: View {
    let imagem: String

    let acao: () -> Void
    
    var body: some View {
        Button(action: acao) {
                Image(imagem)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160, height: 180)
            
            
        }
    }
}

struct BotaoSecundario: View {
    let titulo: String
    var simbolo: String?
    let acao: () -> Void

    var body: some View {
        Button(action: acao) {
            HStack(spacing: 8) {
                if let simbolo {
                    Image(systemName: simbolo)
                }
                Text(titulo)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color(.corBotaoClaro))
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .tint(Provisorio.textoSecundario)
    }
}


struct FundoSalao: View {
    var cor: Color = Provisorio.destaque

    var body: some View {
        LinearGradient(
            colors: [Provisorio.fundo, cor.opacity(0.18), Provisorio.fundo],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

struct PolaroidCard: View {
    var image: Image?
    
    var body: some View {
        VStack(spacing: 24) {
            if let image = image {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .clipped()
                    .cornerRadius(4)
            }
            
            
            Image("logo-polaroid")
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 30)
                .rotationEffect(.degrees(-4.08))
        }
        .padding()
        .padding(.bottom, 16)
        .background(Color.white)
        .cornerRadius(4)
        .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
    }
}


