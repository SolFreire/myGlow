//
//  BalaoDeFala.swift
//  myGlow
//

import SwiftUI


struct BalaoDeFala: View {


    enum Medida {
        static let canto: CGFloat = 20
        static let traco: CGFloat = 5
        static let recuoHorizontal: CGFloat = 22
        static let recuoVertical: CGFloat = 44
        static let recuoDaAba: CGFloat = 38
        /// A aba e uma capsula centrada na borda de cima: metade dela fica
        /// para dentro do balao. `recuoDaAba` precisa cobrir essa metade.
        static let recuoVerticalDaAba: CGFloat = 5
        static let recuoHorizontalDaAba: CGFloat = 18
        static let recuoLateralDaAba: CGFloat = 22

        static let diametroDoBotao: CGFloat = 58

        static let espacoDoBotao: CGFloat = 44
    }

    enum Cor {
        static let fundo = Color("cor-balao-fundo")
        static let borda = Color("cor-balao-borda")
        static let contexto = Color("cor-balao-borda-secundaria")
        static let sugestao = Color("cor-balao-sugestao")
        static let texto = Color("cor-balao-texto")
    }

    enum Estilo: Equatable {

        case padrao
        case passo
        case contexto
        case sugestao

        /// Cor da borda e da aba.
        var cor: Color {
            switch self {
            case .padrao, .passo: Cor.borda
            case .contexto: Cor.contexto
            case .sugestao: Cor.sugestao
            }
        }

        /// Os botões de navegar acompanham o balão: no contexto histórico o
        /// roxo destoaria da borda ciano, e na dica destoaria do verde.
        var botoes: Paleta.Botao {
            switch self {
            case .padrao, .passo: Paleta.botao
            case .contexto: Paleta.botaoDeContexto
            case .sugestao: Paleta.botaoDeSugestao
            }
        }
    }

    let texto: String
    var estilo: Estilo = .padrao

    var rotulo: String?
    var aoAvancar: (() -> Void)?
    var aoVoltar: (() -> Void)?

    private var forma: RoundedRectangle {
        RoundedRectangle(cornerRadius: Medida.canto)
    }

    var body: some View {

        Text(.init(texto))
            .font(Tipografia.fala)
            .foregroundStyle(Cor.texto)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Medida.recuoHorizontal)
            .padding(.bottom, Medida.recuoVertical)
            .padding(.top, rotulo == nil ? Medida.recuoVertical : Medida.recuoDaAba)
            .padding(.trailing, aoAvancar == nil ? 0 : Medida.espacoDoBotao)
            .background(fundo)
            .overlay(alignment: .topLeading) { aba }
            .overlay(alignment: .bottomTrailing) { avancar }
            .overlay(alignment: .bottomLeading) { voltar }
            .accessibilityElement(children: .contain)
    }

    private var fundo: some View {
        forma
            .fill(Cor.fundo)
            .overlay { forma.stroke(estilo.cor, lineWidth: Medida.traco) }
    }

    @ViewBuilder
    private var aba: some View {
        if let rotulo {
            Text(rotulo)
                .font(Tipografia.nomeDaPersonagem)
                .foregroundStyle(Cor.fundo)
                .padding(.horizontal, Medida.recuoHorizontalDaAba)
                .padding(.vertical, Medida.recuoVerticalDaAba)
                .background(estilo.cor, in: Capsule())
                .padding(.leading, Medida.recuoLateralDaAba)
                .alignmentGuide(.top) { $0[VerticalAlignment.center] }
                // A aba é uma parada própria do VoiceOver: "Passo 1", depois a
                // instrução. Já tentei juntar as duas num rótulo só, e rotular o
                // texto transforma o balão inteiro num elemento — os botões ←
                // e → perdem os nomes deles junto.
                .accessibilityLabel(rotulo)
                .offset(x: 0, y: -Medida.recuoVerticalDaAba - 5)
        }
    }

    @ViewBuilder
    private var avancar: some View {
        if let aoAvancar {
            BotaoCircular(simbolo: "arrow.right", diametro: Medida.diametroDoBotao, cores: estilo.botoes)
            {
                SoundManager.shared.playSoundEffect(named: "botao-efeito")
                aoAvancar()
            }
                .offset(x: Medida.diametroDoBotao / 4, y: Medida.diametroDoBotao / 4)
                .accessibilityLabel("Continuar")
        }
    }

    @ViewBuilder
    private var voltar: some View {
        if let aoVoltar {
            BotaoCircular(simbolo: "arrow.left", diametro: Medida.diametroDoBotao, cores: estilo.botoes){
                SoundManager.shared.playSoundEffect(named: "botao-efeito")
                aoVoltar()
            }
                .offset(x: -Medida.diametroDoBotao / 4, y: Medida.diametroDoBotao / 4)
                .accessibilityLabel("Voltar")
        }
    }
}

struct BotaoCircular: View {
    let simbolo: String
    var diametro: CGFloat = 48
    /// A família de cor. O roxo é o padrão em toda a interface; só o balão de
    /// contexto histórico passa outra.
    var cores: Paleta.Botao = Paleta.botao
    let acao: () -> Void

    var body: some View {
        Button(action: acao) {
            Image(systemName: simbolo)
                .font(.system(size: diametro * 0.42, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: diametro, height: diametro)
                .background(cores.gradiente, in: Circle())
                .overlay {
                    Circle().strokeBorder(cores.claro.opacity(0.9), lineWidth: 1)
                }
                .shadow(color: cores.escuro.opacity(0.4), radius: 6, y: 3)
        }
        .buttonStyle(.plain)
    }
}

#Preview("Os três formatos", traits: .landscapeLeft) {
    ZStack {
        FundoSalao()
        HStack(alignment: .top, spacing: 20) {
            BalaoDeFala(
                texto: "Para o nosso primeiro passo, precisamos do **clown**.",
                estilo: .passo,
                rotulo: "Passo 1"
            )
            .frame(width: 300)

            BalaoDeFala(
                texto: "A base branca é história! Nos anos 80, em oposição ao padrão bronzeado da época, os góticos usavam a pele pálida inspirada no cinema expressionista.",
                estilo: .contexto,
                rotulo: "Sobre os góticos",
                aoAvancar:{},
                aoVoltar: {}
            )
            .frame(width: 320)
        }
        .padding(24)

        VStack {
            Spacer()
            BalaoDeFala(texto: "Olá, diva! Seja bem-vinda ao salão myGlow!", rotulo: "Edna", aoAvancar: {},aoVoltar: {})
                .padding(.horizontal, 60)
                .padding(.bottom, 12)
            
        }
    }
}
