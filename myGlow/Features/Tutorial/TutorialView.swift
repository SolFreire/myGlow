//
//  TutorialView.swift
//  myGlow
//

import SwiftUI

struct TutorialView: View {
    let subcultura: Subcultura
    let aoTerminar: () -> Void

    @Environment(AppEnvironment.self) private var ambiente
    @State private var vm: TutorialViewModel?

    var body: some View {
        Group {
            if let vm {
                conteudo(vm)
            } else {
                ZStack {
                    FundoSalao(cor: Provisorio.cor(de: subcultura))
                    ProgressView().tint(Provisorio.destaque)
                }
            }
        }
        .navigationBarBackButtonHidden()
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if vm == nil,
               let roteiro = ambiente.roteiro(de: subcultura),
               let suggester = ambiente.suggester(para: subcultura) {
                vm = TutorialViewModel(
                    roteiro: roteiro,
                    suggester: suggester,
                    inventarioRepo: ambiente.inventario,
                    progressoRepo: ambiente.progresso
                )
            }
            await vm?.carregar()

            #if DEBUG
            let etapa = UserDefaults.standard.integer(forKey: "etapaInicial")
            if etapa > 0 { await vm?.irParaEtapa(etapa) }
            for _ in 0..<UserDefaults.standard.integer(forKey: "falaInicial") {
                await vm?.avancar()
            }
            #endif
        }
        .onChange(of: vm?.terminou ?? false) { _, terminou in
            if terminou { aoTerminar() }
        }
    }

    private func conteudo(_ vm: TutorialViewModel) -> some View {
        FundoDeCena(
            nome: "fundo-espelho-tutoriais",
            corDoPlaceholder: Provisorio.cor(de: subcultura),
            emFoco: vm.cenaEmFoco
        )
        .overlay {

            GeometryReader { proxy in
                personagem(vm, em: proxy.size)
            }
            .ignoresSafeArea()
        }
        .overlay(alignment: .bottom) { balao(vm) }
        .overlay(alignment: .topLeading) {
            BotaoDoCanto(papel: .voltarAoSalao).padding(20)
        }
    }


    @ViewBuilder
    private func personagem(_ vm: TutorialViewModel, em cena: CGSize) -> some View {
        let arte = ArteView(
            nome: vm.ilustracaoAtual,
            simbolo: "person.crop.square",
            cor: Provisorio.cor(de: subcultura)
        )
        .shadow(color: .white.opacity(vm.cenaEmFoco ? 0.9 : 0), radius: 12)
        .frame(height: cena.height, alignment: .bottom)

        switch vm.posicaoDaPersonagem {
        case .aoCentro:
            arte.frame(width: cena.width)

        case .aEsquerda:
            arte
                .frame(width: cena.width * Cena.larguraDaPersonagemNoPasso)
                .frame(width: cena.width, alignment: .leading)
        }
    }


    private enum Cena {
        static let recuoLateralDoBalaoLargo: CGFloat = 60
        static let larguraDoBalaoLateral: CGFloat = 0.44
        static let larguraDaPersonagemNoPasso: CGFloat = 0.69
    }

    @ViewBuilder
    private func balao(_ vm: TutorialViewModel) -> some View {
        if vm.falaAtual != nil || vm.estiloDaFala == .sugestao {
            // O voltar só aparece quando há para onde recuar.
            let balao = BalaoDeFala(
                texto: vm.textoDoBalao,
                estilo: vm.estiloDaFala,
                rotulo: vm.rotuloDaFala,
                aoAvancar: { Task { await vm.avancar() } },
                aoVoltar: vm.podeVoltar ? { Task { await vm.voltar() } } : nil
            )

            switch vm.estiloDaFala {
            case .padrao:
                balao
                    .padding(.horizontal, Cena.recuoLateralDoBalaoLargo)
                    .padding(.bottom, 12)

            case .passo, .contexto, .sugestao:
                balao
                    .containerRelativeFrame(.horizontal) { largura, _ in largura * Cena.larguraDoBalaoLateral }
                    .padding(.trailing, 32)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
            }
        }
    }
}
