//
//  RootView.swift
//  myGlow
//

import SwiftUI


struct RootView: View {
    @Environment(AppEnvironment.self) private var ambiente
    @AppStorage("primeiroUsoConcluido") private var primeiroUsoConcluido = false

    @State private var emOnboarding: Bool?
    @State private var mostrandoAjustes = false

    @State private var lembrancas: LembrancaViewModel?

    @State private var jogou = {
        #if DEBUG
        AppRoute.pularTelaInicial
        #else
        false
        #endif
    }()
    @State private var caminho: [AppRoute] = {
        #if DEBUG
        AppRoute.caminhoDeLancamento
        #else
        []
        #endif
    }()

    var body: some View {
        Group {
            if let erro = ambiente.erroDeRoteiro {
                TelaDeErroDeRoteiro(mensagem: erro)
            } else if !jogou && caminho.isEmpty {
                TelaInicialView { jogou = true }
            } else if emOnboarding ?? !primeiroUsoConcluido {
                OnboardingView { subculturaEscolhida in
                    caminho = [.tutorial(subculturaEscolhida)]
                    primeiroUsoConcluido = true
                    emOnboarding = false
                }
            } else {
                salao
            }
        }
        .tint(Cores.destaque)
        .environment(\.abrirAjustes) { withAnimation(.snappy) { mostrandoAjustes = true } }
        .overlay {
            if mostrandoAjustes {
                BalaoAjustes {
                    withAnimation(.snappy) { mostrandoAjustes = false }
                }
            }
        }
    }

    private var salao: some View {
        NavigationStack(path: $caminho) {
            SalaoView(
                desbloqueadas: lembrancas?.concluidas ?? [],
                aoSentar: { caminho.append(.selecaoDeExperiencia) },
                aoNavegar: { caminho.append($0) }
            )
            .navigationDestination(for: AppRoute.self) { rota in
                switch rota {
                case .cadastro:
                    CadastroView(modo: .edicao) { caminho.removeLast() }
                case .selecaoDeExperiencia:
                    SelecaoDeExperienciaView { subcultura in
                        caminho.append(.tutorial(subcultura))
                    }
                case let .tutorial(subcultura):
                    TutorialView(subcultura: subcultura) {
                        caminho.append(.camera(subcultura))
                    }
                case let .camera(subcultura):
                    CameraView(subcultura: subcultura) {
                        caminho = [.galeria]
                    }
                case .galeria:
                    GaleriaView(aoAbrirFoto: { foto in
                        caminho.append(.detalheFoto(foto))
                    })
                case let .detalheFoto(foto):
                    DetalheFotoView(foto: foto) {
                        caminho.removeLast()
                    }
                }
            }
        }

        .task(id: caminho) {
            if lembrancas == nil {
                lembrancas = LembrancaViewModel(progresso: ambiente.progresso)
            }
            await lembrancas?.carregar()
        }
        .environment(\.voltarAoSalao) { caminho.removeAll() }
    }
}

private struct TelaDeErroDeRoteiro: View {
    let mensagem: String

    var body: some View {
        ZStack {
            FundoSalao()
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                Text("O salão não abriu hoje")
                    .font(Tipografia.secao)
                Text(mensagem)
                    .font(Tipografia.corpo)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Cores.textoSecundario)
            }
            .foregroundStyle(Cores.texto)
            .padding(40)
        }
    }
}
