//
//  RootView.swift
//  myGlow
//

import SwiftUI


struct RootView: View {
    @Environment(AppEnvironment.self) private var ambiente
    @AppStorage("primeiroUsoConcluido") private var primeiroUsoConcluido = false

    @State private var emOnboarding: Bool?
    /// Dono único de quais lembranças já foram conquistadas. Fica aqui, e não
    /// dentro do salão, porque o salão é a raiz da pilha e nunca desaparece —
    /// um `.task` lá dentro rodaria uma vez só e o objeto recém-conquistado só
    /// apareceria no próximo lançamento do app.
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
        .tint(Provisorio.destaque)
    }

    private var salao: some View {
        NavigationStack(path: $caminho) {
            SalaoView(
                desbloqueadas: lembrancas?.concluidas ?? [],
                aoSentar: { caminho.append(.selecaoDeExperiencia) },
                aoNavegar: { caminho.append($0) },
                aoTocarLembranca: { caminho.append(.lembranca($0)) }
            )
            .navigationDestination(for: AppRoute.self) { rota in
                switch rota {
                case .cadastro:
                    CadastroView(modo: .edicao) { caminho.removeLast() }
                case .selecaoDeExperiencia:
                    SelecaoDeExperienciaView { subcultura in
                        caminho.append(.tutorial(subcultura))
                    }
                case let .lembranca(subcultura):
                    LembrancaView(
                        subcultura: subcultura,
                        desbloqueado: lembrancas?.desbloqueado(subcultura) ?? false
                    )
                case let .tutorial(subcultura):
                    TutorialView(subcultura: subcultura) {
                        caminho.append(.camera(subcultura))
                    }
                case let .camera(subcultura):
                    CameraView(subcultura: subcultura) {
                        caminho = [.galeria]
                    }
                case .galeria:
                    GaleriaView()
                }
            }
        }
        // Relê o progresso a cada mudança de rota — em particular ao voltar do
        // tutorial, que é quando uma lembrança nova passa a existir. São três
        // registros; reler de mais é barato, reler de menos deixa o salão
        // desatualizado bem no momento da recompensa.
        .task(id: caminho) {
            if lembrancas == nil {
                lembrancas = LembrancaViewModel(progresso: ambiente.progresso)
            }
            await lembrancas?.carregar()
        }
        // Voltar ao salão é esvaziar a pilha — vale de qualquer profundidade, e
        // interrompe a experiência em andamento se houver uma.
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
                    .foregroundStyle(Provisorio.textoSecundario)
            }
            .foregroundStyle(Provisorio.texto)
            .padding(40)
        }
    }
}
