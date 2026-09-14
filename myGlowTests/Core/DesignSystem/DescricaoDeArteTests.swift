//
//  DescricaoDeArteTests.swift
//  myGlowTests
//

import Foundation
import Testing
@testable import myGlow

/// As artes que o VoiceOver precisa enxergar.
///
/// Fundos e ícones dizem onde a pessoa está e o que há na cena — sem eles a
/// navegação por voz fica sem contexto. As personagens ficam de fora por
/// decisão: quem usa VoiceOver acompanha o tutorial pela fala do balão.
@Suite("Descrição das artes")
struct DescricaoDeArteTests {

    /// Os cenários. São os que hoje somem por completo do VoiceOver.
    static let fundos = [
        "fundo-tela-inicial",
        "fundo-salao",
        "fundo-salao-menu",
        "fundo-espelho-tutoriais",
        "fundo-galeria",
        "fundo-salvar-foto"
    ]

    /// Os objetos. No salão eles já são lidos pelo rótulo do botão; a descrição
    /// entra quando a lembrança abre em destaque, e aí a arte fica sozinha.
    static let objetos = [
        "icone-aranha-lucy",
        "icone-urso-sana",
        "icone-disco-cindy",
        "icone-maleta",
        "icone-cadeira-salao",
        "icone-album-fotos",
        "maleta-aberta"
    ]

    static let descritiveis = fundos + objetos

    /// Este teste **nasce vermelho de propósito**: ele nomeia, uma a uma, as
    /// artes que ainda esperam texto no `Acessibilidade.xcstrings`. Vai ficando
    /// verde conforme o catálogo é preenchido, e depois vira a rede que pega
    /// arte nova entrando sem descrição.
    @Test("Toda arte descritível tem descrição", arguments: descritiveis)
    func temDescricao(asset: String) {
        #expect(
            DescricaoDeArte.para(asset) != nil,
            "Falta a descrição de \(asset) no Acessibilidade.xcstrings"
        )
    }

    /// Uma descrição vazia passaria pela checagem acima e faria o VoiceOver
    /// anunciar uma imagem sem dizer nada — pior do que deixá-la decorativa.
    @Test("Nenhuma descrição é vazia", arguments: descritiveis)
    func descricaoNaoEVazia(asset: String) {
        guard let descricao = DescricaoDeArte.para(asset) else { return }
        #expect(!descricao.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    /// Sem entrada no catálogo a arte tem de continuar decorativa. Se isto
    /// falhar, o `ArteView` passa a anunciar a chave crua — o VoiceOver leria
    /// "arte.personagem-lucy" em voz alta.
    @Test("Arte sem entrada no catálogo continua decorativa")
    func semEntradaFicaDecorativa() {
        #expect(DescricaoDeArte.para("personagem-lucy") == nil)
        #expect(DescricaoDeArte.para("asset-que-nao-existe") == nil)
    }
}
