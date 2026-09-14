//
//  AssetsTests.swift
//  myGlowTests
//

import Testing
import UIKit
@testable import myGlow


@Suite("Assets do catálogo")
@MainActor
struct AssetsTests {

    nonisolated static let nomes = [
        "fundo-tela-inicial", "fundo-salao",
        "maleta-aberta", "personagem-edna",
        "card-gotica", "card-gyaru", "card-newRomantic",
        "icone-maleta", "icone-album"
    ] + CatalogoMaquiagem.todos.map(\.asset)

    nonisolated static let nomesDeCores = [
        "cor-botao", "cor-balao-borda", "cor-balao-borda-secundaria",
        "fundo-cadastro", "fundo-cadastro-escuro"
    ]

    @Test("Carregar um asset nunca derruba o app")
    func carregaSemExplodir() {
        for nome in Self.nomes {
            guard let imagem = UIImage(named: nome) else { continue }

            #expect(imagem.size.width > 0, "\(nome) carregou com largura zero")
            #expect(imagem.size.height > 0, "\(nome) carregou com altura zero")
            #expect(imagem.scale > 0, "\(nome) carregou com escala inválida")
        }
    }

    @Test("Nome de cor não é confundido com imagem", arguments: nomesDeCores)
    func corNaoEImagem(_ nome: String) {
        #expect(Arte.existe(nome) == false, "\(nome) é um color set, não um image set")
        #expect(Arte.proporcao(nome) == nil)
    }
}
