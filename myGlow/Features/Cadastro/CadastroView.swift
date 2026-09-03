//
//  CadastroView.swift
//  myGlow
//

import SwiftUI


struct CadastroView: View {
    let modo: CadastroViewModel.Modo
    let aoConcluir: () -> Void

    @Environment(AppEnvironment.self) private var ambiente
    @State private var vm: CadastroViewModel?
    @State private var molduraDaMaleta: CGRect = .zero
    @State private var maletaEmDestaque = false

    private let espaco = "cadastro"

    var body: some View {
        ZStack {
            Fundo.gradiente.ignoresSafeArea()

            if let vm {
                conteudo(vm)
            } else {
                ProgressView().tint(Paleta.botao.base)
            }
        }
        .coordinateSpace(name: espaco)
        .navigationBarBackButtonHidden(modo == .onboarding)
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .topLeading) {
            BotaoDoCanto(papel: modo == .onboarding ? .ajustes : .voltarAoSalao)
                .padding(20)
        }
        .task {
            if vm == nil {
                vm = CadastroViewModel(repositorio: ambiente.inventario)
            }
            await vm?.carregar()
        }
    }

    private func conteudo(_ vm: CadastroViewModel) -> some View {

        GeometryReader { proxy in
            HStack(spacing: 0) {
                maleta(vm)
                    .frame(width: proxy.size.width * 0.60)

                catalogo(vm)
                    .frame(width: proxy.size.width * 0.40)
            }
            .frame(height: proxy.size.height)
        }
    }

    // MARK: - Maleta

    private func maleta(_ vm: CadastroViewModel) -> some View {
        GeometryReader { proxy in
            let largura = proxy.size.width
            let altura = largura / (Arte.proporcao("maleta-aberta") ?? 1)
            ZStack(alignment: .bottom) {
                Color.clear

                ArteView(nome: "maleta-aberta")
                .frame(width: largura, height: altura)
                .overlay { interiorDaMaleta(vm) }
                .overlay {
                    if maletaEmDestaque {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Paleta.botao.base, lineWidth: 4)
                    }
                }
                .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(espaco)) } action: {
                    molduraDaMaleta = $0
                }
                .animation(.spring(duration: 0.25), value: maletaEmDestaque)
                .accessibilityLabel("Minha maleta, \(vm.quantidadeNaMaleta) itens")
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .bottom)
            .clipped()
        }
    }


    private func interiorDaMaleta(_ vm: CadastroViewModel) -> some View {
        GeometryReader { proxy in
            let l = proxy.size.width
            let a = proxy.size.height

            Group {
                if vm.itensNaMaleta.isEmpty {
                    Text("Adicione seus itens de maquiagens")
                        .font(Tipografia.secao)
                        .foregroundStyle(Provisorio.texto)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: l * 0.18), spacing: 10)],
                            spacing: 10
                        ) {
                            ForEach(vm.itensNaMaleta) { item in
                                CartaoDeItem(item: item, dentroDaMaleta: true) {
                                    Task { await vm.alternar(item) }
                                }
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .frame(width: l * (Interior.direita - Interior.esquerda),
                   height: a * (Interior.base - Interior.topo))
            .offset(x: l * Interior.esquerda, y: a * Interior.topo)
        }
    }

    /// O fundo desta tela é um degradê entre duas cores do catálogo, e não uma
    /// ilustração — como todo degradê do app, de cima para baixo.
    private enum Fundo {
        static let gradiente = LinearGradient(
            colors: [Color("fundo-cadastro"), Color("fundo-cadastro-escuro")],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// A área útil dentro da mala, em fração da arte: a metade de baixo, onde
    /// os produtos se acomodam — a de cima é a tampa aberta.
    private enum Interior {
        static let esquerda: CGFloat = 0.06
        static let direita: CGFloat = 0.94
        static let topo: CGFloat = 0.52
        static let base: CGFloat = 0.94
    }

    // MARK: - Catálogo

    /// O catálogo.
    ///
    /// Sem conta de largura: a coluna recebe uma largura explícita de quem a
    /// posiciona, as colunas do grid são flexíveis e o cartão fica quadrado pela
    /// própria proporção. Calcular o lado à mão exigia descontar recuo externo,
    /// interno e vão entre colunas — e errar qualquer um deles jogava o grid
    /// para fora da tela.
    private func catalogo(_ vm: CadastroViewModel) -> some View {
        VStack(spacing: 12) {
            BotaoPrimario(titulo: "Salvar", simbolo: "checkmark", preencheLargura: false) {
                aoConcluir()
            }
            .disabled(vm.quantidadeNaMaleta == 0 && modo == .onboarding)

            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
                    spacing: 12
                ) {
                    ForEach(vm.itensForaDaMaleta) { item in
                        CartaoDeItem(
                            item: item,
                            dentroDaMaleta: false,
                            espaco: espaco,
                            aoTocar: { Task { await vm.alternar(item) } },
                            aoArrastar: { ponto in
                                maletaEmDestaque = ArrasteMaleta.acertou(ponto: ponto, maleta: molduraDaMaleta)
                            },
                            aoSoltar: { ponto in
                                maletaEmDestaque = false
                                let acertou = ArrasteMaleta.acertou(ponto: ponto, maleta: molduraDaMaleta)
                                if acertou {
                                    Task { await vm.adicionar(item) }
                                }
                                return acertou
                            }
                        )
                    }
                }
                .padding(14)
            }
            .scrollIndicators(.hidden)
            .background(
                Provisorio.painelDoCatalogo,
                in: UnevenRoundedRectangle(topLeadingRadius: 24, topTrailingRadius: 24)
            )
            .ignoresSafeArea(edges: .bottom)

            if let erro = vm.erro {
                Text(erro).font(.caption).foregroundStyle(.red)
            }
        }
        .padding(.top, 16)
    }
}


private struct CartaoDeItem: View {
    let item: ItemCatalogo
    let dentroDaMaleta: Bool
    var espaco = ""
    let aoTocar: () -> Void
    var aoArrastar: ((CGPoint) -> Void)?
    var aoSoltar: ((CGPoint) -> Bool)?

    @State private var deslocamento: CGSize = .zero
    @State private var arrastando = false

    var body: some View {
        ArteView(nome: item.asset)
            .padding(dentroDaMaleta ? 2 : 10)
            .aspectRatio(1, contentMode: .fit)
            .background {
                if !dentroDaMaleta {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Provisorio.cartaoDoCatalogo)
                }
            }
            .scaleEffect(arrastando ? 1.12 : 1)
            .offset(deslocamento)
            .zIndex(arrastando ? 1 : 0)
            .onTapGesture(perform: aoTocar)
            .gesture(arraste)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(item.nome)
            .accessibilityValue(dentroDaMaleta ? "Na maleta" : "Fora da maleta")
            .accessibilityHint(
                dentroDaMaleta
                    ? "Toque duas vezes para tirar da maleta"
                    : "Toque duas vezes para guardar na maleta"
            )
            .accessibilityAddTraits(.isButton)
            .sensoryFeedback(.selection, trigger: dentroDaMaleta)
    }


    private var arraste: some Gesture {
        DragGesture(minimumDistance: 12, coordinateSpace: .named(espaco))
            .onChanged { valor in
                guard let aoArrastar else { return }
                arrastando = true
                deslocamento = valor.translation
                aoArrastar(valor.location)
            }
            .onEnded { valor in
                guard let aoSoltar else { return }
                arrastando = false
                _ = aoSoltar(valor.location)
                withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
                    deslocamento = .zero
                }
            }
    }
}
