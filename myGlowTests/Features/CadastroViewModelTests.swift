//
//  CadastroViewModelTests.swift
//  myGlowTests
//

import CoreGraphics
import Testing
@testable import myGlow

@Suite("Cadastro da maleta")
@MainActor
struct CadastroViewModelTests {
    @Test("O toque guarda e tira o item da maleta")
    func toqueAlterna() async throws {
        let vm = CadastroViewModel(repositorio: InventarioEmMemoria())
        let batom = try #require(CatalogoMaquiagem.item(id: "batom"))
        await vm.carregar()

        await vm.alternar(batom)
        #expect(vm.estaNaMaleta("batom"))
        #expect(vm.quantidadeNaMaleta == 1)

        await vm.alternar(batom)
        #expect(!vm.estaNaMaleta("batom"))
        #expect(vm.quantidadeNaMaleta == 0)
    }

    /// O arraste só guarda. Arrastar um item que já está na maleta não pode
    /// tirá-lo de lá — seria um gesto que faz o contrário do que aparenta.
    @Test("O arraste só adiciona, nunca remove")
    func arrasteSoAdiciona() async throws {
        let vm = CadastroViewModel(repositorio: InventarioEmMemoria())
        let gloss = try #require(CatalogoMaquiagem.item(id: "gloss"))
        await vm.carregar()

        await vm.adicionar(gloss)
        await vm.adicionar(gloss)

        #expect(vm.quantidadeNaMaleta == 1)
    }

    @Test("Carrega a maleta já cadastrada")
    func carregaOQueJaExiste() async {
        let vm = CadastroViewModel(repositorio: InventarioEmMemoria(ids: ["clown", "pancake"]))

        await vm.carregar()

        #expect(vm.maleta == ["clown", "pancake"])
        #expect(vm.itensNaMaleta.map(\.id).sorted() == ["clown", "pancake"])
    }

    @Test("Falha do repositório vira mensagem, não crash")
    func erroViraMensagem() async throws {
        let repo = InventarioEmMemoria()
        repo.erroAoAdicionar = SuggestionError.respostaInvalida
        let vm = CadastroViewModel(repositorio: repo)
        await vm.carregar()

        await vm.alternar(try #require(CatalogoMaquiagem.item(id: "gloss")))

        #expect(vm.erro != nil)
        #expect(!vm.estaNaMaleta("gloss"))
    }
}

/// A checagem do arraste vive fora do gesture handler justamente para ser
/// testável sem UI.
@Suite("Acerto do arraste na maleta")
struct ArrasteMaletaTests {
    private let maleta = CGRect(x: 100, y: 100, width: 200, height: 200)

    @Test("Ponto dentro da maleta acerta", arguments: [
        CGPoint(x: 150, y: 150),
        CGPoint(x: 100, y: 100),
        CGPoint(x: 300, y: 300)
    ])
    func dentro(_ ponto: CGPoint) {
        #expect(ArrasteMaleta.acertou(ponto: ponto, maleta: maleta))
    }

    @Test("Ponto bem fora não acerta", arguments: [
        CGPoint(x: 0, y: 0),
        CGPoint(x: 500, y: 150),
        CGPoint(x: 150, y: 500)
    ])
    func fora(_ ponto: CGPoint) {
        #expect(!ArrasteMaleta.acertou(ponto: ponto, maleta: maleta))
    }

    @Test("A tolerância perdoa quem solta rente à borda")
    func toleranciaNaBorda() {
        #expect(ArrasteMaleta.acertou(ponto: CGPoint(x: 80, y: 150), maleta: maleta))
        #expect(!ArrasteMaleta.acertou(ponto: CGPoint(x: 50, y: 150), maleta: maleta))
    }

    @Test("Sem moldura medida ainda, nada acerta")
    func maletaSemMoldura() {
        #expect(!ArrasteMaleta.acertou(ponto: CGPoint(x: 0, y: 0), maleta: .zero))
    }
}
