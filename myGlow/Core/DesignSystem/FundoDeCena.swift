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
    }
}

extension EnvironmentValues {
    /// Abre o balão de ajustes por cima de tudo.
    ///
    /// `BotaoAjustes` aparece em seis telas, sempre num cantinho de 48pt —
    /// pequeno demais para hospedar o `.overlay` de tela cheia do balão (o
    /// `.overlay` propõe o tamanho do próprio botão para o que está por
    /// cima). Por isso o botão só avisa, e quem de fato mostra o balão é a
    /// `RootView`, que já cobre a tela inteira — mesma ideia de
    /// `voltarAoSalao` ao lado.
    @Entry var abrirAjustes: () -> Void = {}
}

/// Os ajustes como balão sobre o salão — mesmo modelo de
/// `LembrancaEmDestaque` e do card em foco da seleção de experiência: um
/// véu cobre a tela, o conteúdo real fica só na área do balão, e tocar fora
/// dele fecha. Sem `.sheet`: nada aqui pede a navegação própria de uma tela.
struct BalaoAjustes: View {
    @AppStorage("efeitosSonorosLigados") private var efeitosSonorosLigados = true
    @AppStorage("musicaLigada") private var musicaLigada = true
    @Environment(\.dismiss) private var fechar
    
    var estilo: BalaoDeFala.Estilo = .padrao
    let aoFechar: () -> Void

    private var forma: RoundedRectangle {
        RoundedRectangle(cornerRadius: BalaoDeFala.Medida.canto)
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture(perform: aoFechar)

            conteudo()
        }
    }

    private func conteudo() -> some View {
        VStack(spacing: 40) {
            VStack(spacing: 20) {
                Toggle("Efeitos sonoros", isOn: $efeitosSonorosLigados)

                Toggle("Música", isOn: $musicaLigada)
                    .onChange(of: musicaLigada) { _, novoValor in
                        SoundManager.shared.playBackgroundMusic(isOn: novoValor)
                    }
            }
            .font(.system(size: 20, weight: .medium, design: .rounded))

            HStack(spacing: 5) {
                Text("Música por")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                Link("VIV3LI", destination: URL(string: "https://www.youtube.com/watch?v=ymTjeOIUcts")!)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
            }
        }
        .foregroundStyle(BalaoDeFala.Cor.texto)
        .tint(estilo.cor)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, BalaoDeFala.Medida.recuoHorizontal + 25)
        .padding(.bottom, BalaoDeFala.Medida.recuoVertical)
        .padding(.top, BalaoDeFala.Medida.recuoDaAba)
        .background(fundo)
        .overlay(alignment: .top) { aba }
        .frame(maxWidth: 330)
    }

    private var fundo: some View {
        forma
            .fill(BalaoDeFala.Cor.fundo)
            .overlay { forma.stroke(estilo.cor, lineWidth: BalaoDeFala.Medida.traco) }
    }

    @ViewBuilder
    private var aba: some View {
        Text("Ajustes")
            .font(Tipografia.nomeDaPersonagem)
            .foregroundStyle(BalaoDeFala.Cor.fundo)
            .padding(.horizontal, BalaoDeFala.Medida.recuoHorizontalDaAba)
            .padding(.vertical, BalaoDeFala.Medida.recuoVerticalDaAba)
            .background(estilo.cor, in: Capsule())
            .accessibilityLabel("Ajustes")
            .offset(y: -BalaoDeFala.Medida.recuoVerticalDaAba - 5)
    }
}

//Alert de quando está em uma experiência e quer voltar para o salão
struct VoltarAlert: View {
    @Environment(\.dismiss) private var fechar
    @Environment(\.voltarAoSalao) private var voltarAoSalao
    var estilo: BalaoDeFala.Estilo = .padrao
    
    private var forma: RoundedRectangle {
        RoundedRectangle(cornerRadius: BalaoDeFala.Medida.canto)
    }
    
    var body: some View {
        conteudo()
    }
    
    private func conteudo() -> some View {
        VStack (spacing: 40){
            VStack(spacing: 4) {
                Text("Tem certeza de que deseja voltar para o salão?")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                Text("Ao voltar para o salão, você perderá todo o progresso")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 36)
            }
            HStack (spacing: 48){
                Button {
                    SoundManager.shared.playSoundEffect(named: "botao-efeito")
                    voltarAoSalao()
                } label: {
                    Text("Voltar")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundStyle(.corBalaoBorda)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 13)
                .overlay(RoundedRectangle(cornerRadius: 30)
                    .stroke(Color.corBalaoBorda, lineWidth: 3))
                BotaoPrimario(titulo: "Continuar", preencheLargura: false){
                    SoundManager.shared.playSoundEffect(named: "botao-efeito")
                    fechar()
                }
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, BalaoDeFala.Medida.recuoHorizontal + 16)
        .padding(.bottom, BalaoDeFala.Medida.recuoVertical - 12)
        .padding(.top, BalaoDeFala.Medida.recuoDaAba - 12)
        .background(fundo)
        .frame(maxWidth: 400)
    }
    
    private var fundo: some View {
        forma
            .fill(BalaoDeFala.Cor.fundo)
            .overlay { forma.stroke(estilo.cor, lineWidth: BalaoDeFala.Medida.traco) }
    }
}


#Preview {
    ZStack {
        FundoSalao()
        BalaoAjustes(aoFechar: {})
    }
}
