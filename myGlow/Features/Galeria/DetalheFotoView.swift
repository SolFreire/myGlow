import SwiftUI
import SwiftData

struct DetalheFotoView: View {
    @Environment(\.modelContext) var modelContext
    let foto: FotoSalva
    let aoVoltar: () -> Void
    @State var mostrandoConfirmacaoExclusao: Bool = false

    var body: some View {
        ZStack {
            Image("fundo-salvar-foto")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea(edges: .all)

            HStack(spacing: 24) {
                if let uiImage = UIImage(data: foto.dados) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .rotationEffect(.degrees(-4.08))
                        .frame(width: 250, height: 250)
                }
                buttonsView()
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BotaoCircular(simbolo: "door.right.hand.open") {
                        SoundManager.shared.playSoundEffect(named: "botao-efeito")
                        aoVoltar()
                    }
                }
                .sharedBackgroundVisibility(.hidden)
            }

            if mostrandoConfirmacaoExclusao {
                BalaoDeletar(
                    aoConfirmarExclusao: {
                        modelContext.delete(foto)
                        aoVoltar()
                    },
                    aoFechar: {
                        withAnimation(.snappy) { mostrandoConfirmacaoExclusao = false }
                    }
                )
                .transition(.opacity)
            }
        }
    }

    private func buttonsView() -> some View {
        HStack {
            ShareLink(item: renderedPolaroid, preview: SharePreview(Text("Polaroid"), image: renderedPolaroid)) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Exportar")
                }
            }
            .font(Tipografia.destaqueDoCorpo)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .frame(maxWidth: nil)
            .background(Paleta.botao.gradiente, in: Capsule())

            BotaoPrimario(titulo: String(localized: "Deletar"), simbolo: "trash", cores: Paleta.botaoDeletarFoto, preencheLargura: false) {
                mostrandoConfirmacaoExclusao = true
            }
        }
        .padding()
    }

    private var polaroidImage: UIImage? {
        UIImage(data: foto.dados)
    }

    private var renderedPolaroid: Image {
        if let polaroidImage {
            Image(uiImage: polaroidImage)
                .resizable()
        } else {
            Image("Doll1")
        }
    }
}
