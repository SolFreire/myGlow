
//
//  Componentes.swift
//  myGlow
//

import SwiftUI

struct BotaoPrimario: View {
    var titulo: String? = nil
    var simbolo: String?
    var tamanho: Tamanho = .padrao
    var cores: Paleta.Botao = Paleta.botao
    var preencheLargura = true
    var simboloAoFim = false
    let acao: () -> Void

    enum Tamanho {
        case padrao
        case grande
        case camera

        var fonte: Font {
            switch self {
            case .padrao: Tipografia.destaqueDoCorpo
            case .grande: Tipografia.botao
            case .camera: Tipografia.titulo
            }
        }

        var recuoVertical: CGFloat {
            switch self {
            case .padrao: 14
            case .grande: 20
            case .camera: 16
            }
        }

        var recuoHorizontal: CGFloat {
            switch self {
            case .padrao: 24
            case .grande: 56
            case .camera: 20
            }
        }
    }

    var body: some View {
        Button(action: acao) {
            HStack(spacing: 8) {
                if let simbolo, !simboloAoFim {
                    Image(systemName: simbolo)
                }
                if let titulo {
                    Text(titulo)
                }
                if let simbolo, simboloAoFim {
                    Image(systemName: simbolo)
                }
            }
            .font(tamanho.fonte)
            .foregroundStyle(.white)
            .padding(.horizontal, tamanho.recuoHorizontal)
            .padding(.vertical, tamanho.recuoVertical)
            .frame(maxWidth: preencheLargura ? .infinity : nil)
            .background(cores.gradiente, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct CardMaqueadora: View {
    let background: String
    let character: String
    let nomeDaPersonagem: String
    let descricao: String
    let cor: String
    var emFoco: Bool = false
    let acao: () -> Void

    var body: some View {
        Button(action: acao) {
            ZStack {
                Image(background)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 160, height: 180)
                Image(character)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 265, height: 165, alignment: .bottomTrailing)
                VStack(alignment: .leading, spacing: 6) {
                    Text(nomeDaPersonagem)
                        .font(Tipografia.titulo)
                        .foregroundStyle(Color(cor))

                    Text(descricao)
                        .font(Tipografia.legenda)
                        .foregroundStyle(Color(cor))
                        .multilineTextAlignment(.leading)
                        .frame(width: 125, height: 80, alignment: .topLeading)

                }
                .frame(width: 230, height: 130, alignment: .topLeading)

            }

        }
        .accessibilityLabel("\(nomeDaPersonagem), \(descricao)")
        .accessibilityHint(emFoco ? "Toque para selecionar" : "Toque para focar")
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
        .tint(Cores.textoSecundario)
    }
}


struct FundoSalao: View {
    var cor: Color = Cores.destaque

    var body: some View {
        LinearGradient(
            colors: [Cores.fundo, cor.opacity(0.18), Cores.fundo],
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


