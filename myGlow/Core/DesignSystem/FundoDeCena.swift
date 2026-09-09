//
//  FundoDeCena.swift
//  myGlow
//

import SwiftUI


struct FundoDeCena: View {
    let nome: String
    var corDoPlaceholder: Color = Cores.destaque
    var emFoco = false

    var body: some View {
        conteudo
            .blur(radius: emFoco ? 3 : 0)
            .overlay {
                if emFoco {
                    Color("fundo-tutorial-foco").opacity(0.2)
                        .ignoresSafeArea(edges: .all)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: emFoco)
    }

    @ViewBuilder
    private var conteudo: some View {
        if Arte.existe(nome) {
            GeometryReader { proxy in
                Image(nome)
                    .resizable()
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
            }
            .ignoresSafeArea()
            .descricaoDaArte(nome)
        } else {
            FundoSalao(cor: corDoPlaceholder)
        }
    }
}

struct BotaoAjustes: View {
    @State private var mostrandoAjustes = false

    var body: some View {
        BotaoCircular(simbolo: "gearshape.fill", diametro: 48) {
            SoundManager.shared.playSoundEffect(named: "botao-efeito")
            mostrandoAjustes = true
        }
        .accessibilityLabel("Ajustes")
        .sheet(isPresented: $mostrandoAjustes) {
            AjustesView()
                .presentationBackground(.clear)
                .presentationCornerRadius(AjustesView.Medida.canto)
                .presentationDetents([.height(AjustesView.Medida.altura)])
        }
    }
}

/// O balão de ajustes: mesma família visual do `BalaoDeFala` (fundo branco,
/// borda roxa, aba na borda de cima) — só sem fala, com toggles.
struct AjustesView: View {
    @AppStorage("somLigado") private var somLigado = true
    @AppStorage("musicaLigada") private var musicaLigada = true

    fileprivate enum Medida {
        static let canto: CGFloat = 24
        static let traco: CGFloat = 5
        static let altura: CGFloat = 380
        static let recuoDaAba: CGFloat = 38
    }

    private enum Musica {
        static let artista = "VIV3LI"
        static let fonte = "https://youtu.be/ymTjeOlUcts?si=swS8EDfvewnAbP6s"
    }

    var body: some View {
        VStack(spacing: 24) {
            Toggle("Som", isOn: $somLigado)
            Toggle("Música", isOn: $musicaLigada)
                .onChange(of: musicaLigada) { _, novoValor in
                    SoundManager.shared.playBackgroundMusic(isOn: novoValor)
                }

            VStack(spacing: 4) {
                (Text("Música por ") + Text(Musica.artista).fontWeight(.bold))
                Text("Fonte: \(Musica.fonte)")
                    .font(.footnote)
            }
            .font(Tipografia.legenda)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
        }
        .foregroundStyle(BalaoDeFala.Cor.texto)
        .tint(BalaoDeFala.Cor.borda)
        .padding(.horizontal, 22)
        .padding(.bottom, 32)
        .padding(.top, Medida.recuoDaAba)
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: Medida.canto)
                .fill(BalaoDeFala.Cor.fundo)
                .overlay {
                    RoundedRectangle(cornerRadius: Medida.canto)
                        .stroke(BalaoDeFala.Cor.borda, lineWidth: Medida.traco)
                }
        )
        .overlay(alignment: .top) {
            Text("Ajustes")
                .font(Tipografia.nomeDaPersonagem)
                .foregroundStyle(BalaoDeFala.Cor.fundo)
                .padding(.horizontal, 24)
                .padding(.vertical, 8)
                .background(BalaoDeFala.Cor.borda, in: Capsule())
                .offset(y: -20)
        }
        .padding(.horizontal, 24)
    }
}
