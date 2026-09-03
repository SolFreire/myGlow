//
//  CatalogoMaquiagemTests.swift
//  myGlowTests
//

import Testing
@testable import myGlow

@Suite("Catálogo de maquiagem")
struct CatalogoMaquiagemTests {
    @Test("Ids não se repetem")
    func idsUnicos() {
        let ids = CatalogoMaquiagem.todos.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    /// As sombras entram por cor porque o roteiro pede cor específica — branca
    /// na Sana, roxa na Lucy, azul elétrica na Cindy.
    @Test(
        "Todas as cores de sombra estão no catálogo",
        arguments: ["branca", "preta", "laranja", "azul", "roxa", "magenta", "amarela", "verde"]
    )
    func coresDeSombra(_ cor: String) {
        #expect(CatalogoMaquiagem.item(id: "sombra-\(cor)") != nil)
    }

    @Test("Nenhum item fica sem nome ou sem asset")
    func metadados() {
        for item in CatalogoMaquiagem.todos {
            #expect(!item.nome.isEmpty)
            #expect(item.asset == "item-\(item.id)")
        }
    }

    @Test("Nome desconhecido não derruba a tela")
    func nomeDeIDInexistente() {
        #expect(CatalogoMaquiagem.nome(paraID: "produto-que-nao-existe") == "produto-que-nao-existe")
    }
}
