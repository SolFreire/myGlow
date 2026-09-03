//
//  SalaoView.swift
//  myGlow
//

import SwiftUI

struct SalaoView: View {
    /// Quais lembrancas ja foram conquistadas. So estas sao desenhadas.
    let desbloqueadas: Set<Subcultura>
    let aoSentar: () -> Void
    let aoNavegar: (AppRoute) -> Void
    let aoTocarLembranca: (Subcultura) -> Void

    var body: some View {
        CenaInterativa(cenario: "fundo-salao-menu", proporcaoDaArte: Cena.proporcao) { moldura in
            objetos(moldura)
        }
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .topLeading) { BotaoDoCanto(papel: .ajustes).padding(20) }
    }

    @ViewBuilder
    private func objetos(_ moldura: CGRect) -> some View {
        ObjetoDaCena(
            asset: "icone-cadeira-salao",
            simbolo: "chair.lounge.fill",
            posicao: Cena.cadeira,
            ancora: .bottom,
            largura: 0.145,
            moldura: moldura,
            rotulo: "Sentar e escolher a experiência",
            acao: aoSentar
        )

        ObjetoDaCena(
            asset: "icone-maleta",
            simbolo: "bag.fill",
            posicao: Cena.maleta,
            largura: 0.110,
            moldura: moldura,
            rotulo: "Minha maleta"
        ) {
            aoNavegar(.cadastro)
        }

        ObjetoDaCena(
            asset: "icone-album-fotos",
            simbolo: "photo.stack.fill",
            posicao: Cena.album,
            largura: 0.086,
            moldura: moldura,
            rotulo: "Meu álbum"
        ) {
            aoNavegar(.galeria)
        }

        // A lembranca de uma personagem so aparece depois que a trilha dela
        // termina. Nao existe versao apagada do objeto: enquanto nao foi
        // conquistado, o vao do cenario fica vazio — o `fundo-salao-menu` vem
        // sem os objetos justamente para isso. Assim o salão vai ficando mais
        // cheio conforme a pessoa avanca, sem nunca mostrar algo desligado.
        ForEach(Subcultura.allCases.filter(desbloqueadas.contains)) { subcultura in
            let lembranca = Cena.lembranca(de: subcultura)

            ObjetoDaCena(
                asset: lembranca.asset,
                simbolo: lembranca.simbolo,
                posicao: lembranca.posicao,
                largura: lembranca.largura,
                moldura: moldura,
                rotulo: "Lembrança de \(subcultura.personagem)"
            ) {
                aoTocarLembranca(subcultura)
            }
        }
    }

    /// Onde cada objeto fica sobre a arte, em fração dela.
    ///
    /// Medido no mockup de 852×393. O cenário do hub é o `fundo-salao-menu`, que
    /// vem **sem** os objetos — a sala mobiliada, com os vãos vazios. Isso torna
    /// o encaixe bem mais tolerante: um erro de um ou dois por cento aparece
    /// como um objeto levemente fora do lugar, e não como imagem duplicada.
    ///
    /// É o único lugar a ajustar se o cenário for reenquadrado.
    private enum Cena {
        static let proporcao: CGFloat = 852.0 / 393.0

        /// A cadeira pousa na sombra pintada no chão, por isso ancora pela base.
        static let cadeira = UnitPoint(x: 0.345, y: 0.855)
        static let maleta = UnitPoint(x: 0.477, y: 0.306)
        static let album = UnitPoint(x: 0.177, y: 0.341)

        static func lembranca(de subcultura: Subcultura) -> (asset: String, simbolo: String, posicao: UnitPoint, largura: CGFloat) {
            switch subcultura {
            case .gotica:
                ("icone-aranha-lucy", "ant.fill", UnitPoint(x: 0.518, y: 0.491), 0.045)
            case .gyaru:
                ("icone-urso-sana", "teddybear.fill", UnitPoint(x: 0.826, y: 0.562), 0.074)
            case .newRomantic:
                ("icone-disco-cindy", "opticaldisc.fill", UnitPoint(x: 0.448, y: 0.518), 0.062)
            }
        }
    }
}
