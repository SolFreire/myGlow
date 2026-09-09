//
//  FundoDeCena.swift
//  myGlow
//

import SwiftUI


struct FundoDeCena: View {
    let nome: String
    var corDoPlaceholder: Color = Provisorio.destaque
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
        }
    }
}

struct AjustesView: View {
    @AppStorage("efeitosSonorosLigados") private var efeitosSonorosLigados = true
    @AppStorage("musicaLigada") private var musicaLigada = true
    @Environment(\.dismiss) private var fechar
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Efeitos sonoros", isOn: $efeitosSonorosLigados)
                    
                    Toggle("Música", isOn: $musicaLigada)
                        .onChange(of: musicaLigada) { oldValue, newValue in
                            SoundManager.shared.playBackgroundMusic(isOn: newValue)
                        }
                } footer: {
                    Text("A narração das personagens entra numa próxima versão.")
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Pronto") {
                        fechar()
                    }
                }
            }
        }
    }
}


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
        conteudo()
    }
    
    private func conteudo() -> some View {
        VStack (spacing: 40){
            VStack(spacing: 20) {
                Toggle("Efeitos sonoros", isOn: $efeitosSonorosLigados)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                
                Toggle("Música", isOn: $musicaLigada)
                    .onChange(of: musicaLigada) { oldValue, newValue in
                        SoundManager.shared.playBackgroundMusic(isOn: newValue)
                    }
                    .font(.system(size: 20, weight: .medium, design: .rounded))
            }
            HStack (spacing: 5){
                Text("Música por")
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                Link("VIV3LI", destination: URL(string: "https://www.youtube.com/watch?v=ymTjeOIUcts")!)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, BalaoDeFala.Medida.recuoHorizontal + 25)
        .padding(.bottom, BalaoDeFala.Medida.recuoVertical)
        .padding(.top, BalaoDeFala.Medida.recuoDaAba)
        .background(fundo)
        .overlay(alignment: .topLeading) { aba }
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
            .padding(.leading, BalaoDeFala.Medida.recuoLateralDaAba)
            .alignmentGuide(.top) { $0[VerticalAlignment.center] }
            .accessibilityLabel("Ajustes")
            .offset(x: BalaoDeFala.Medida.recuoLateralDaAba + 73, y: -BalaoDeFala.Medida.recuoVerticalDaAba + 5)
    }
}


#Preview {
    BalaoAjustes(aoFechar: {})
}
