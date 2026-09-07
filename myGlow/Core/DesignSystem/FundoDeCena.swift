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
            .accessibilityHidden(true)
        } else {
            FundoSalao(cor: corDoPlaceholder)
        }
    }
}

struct BotaoAjustes: View {
    @State private var mostrandoAjustes = false

    var body: some View {
        BotaoCircular(simbolo: "gearshape.fill", diametro: 48) {
            mostrandoAjustes = true
        }
        .accessibilityLabel("Ajustes")
        .sheet(isPresented: $mostrandoAjustes) {
            AjustesView()
        }
    }
}

struct AjustesView: View {
    @AppStorage("somLigado") private var somLigado = true
    @Environment(\.dismiss) private var fechar

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Som", isOn: $somLigado)
                        .onChange(of: somLigado) { oldValue, newValue in
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
                    Button("Pronto") { fechar() }
                }
            }
        }
    }
}
