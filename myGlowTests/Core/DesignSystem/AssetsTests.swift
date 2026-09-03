//
//  AssetsTests.swift
//  myGlowTests
//

import Testing
import UIKit
@testable import myGlow

/// Um image set mal montado não dá erro de compilação: ele explode em
/// `UIImage(named:)`, em tempo de execução, na primeira tela que o usa.
@Suite("Assets do catálogo")
@MainActor
struct AssetsTests {
    /// Todos os nomes que o app procura no catálogo.
    nonisolated static let nomes = [
        "fundo-tela-inicial", "fundo-salao",
        "maleta-aberta", "personagem-edna",
        "card-gotica", "card-gyaru", "card-newRomantic",
        "icone-maleta", "icone-album"
    ] + CatalogoMaquiagem.todos.map(\.asset)

    /// Nomes que existem no catálogo como **cor**. Pedir imagem por um deles
    /// derrubava o app; `Arte.existe` agora barra antes.
    nonisolated static let nomesDeCores = [
        "cor-botao", "cor-balao-borda", "cor-balao-borda-secundaria",
        "fundo-cadastro", "fundo-cadastro-escuro"
    ]

    @Test("Carregar um asset nunca derruba o app")
    func carregaSemExplodir() {
        for nome in Self.nomes {
            // Nome inexistente devolve nil — isso é esperado e tratado por
            // `ArteView`. O que não pode acontecer é a carga falhar por má
            // formação do image set.
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
