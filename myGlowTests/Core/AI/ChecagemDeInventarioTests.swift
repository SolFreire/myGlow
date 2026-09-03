//
//  ChecagemDeInventarioTests.swift
//  myGlowTests
//

import Testing
@testable import myGlow

/// A rede de segurança determinística que a PoC pediu: mesmo com as regras nas
/// instructions, o modelo cita produto que a pessoa não tem.
@Suite("Checagem de itens fora da maleta")
struct ChecagemDeInventarioTests {
    @Test("Acusa produto citado que não está na maleta")
    func acusaProdutoDeFora() {
        let fora = ChecagemDeInventario.itensForaDaMaleta(
            emTextos: ["Comece com um pó para selar e depois passe o gloss."],
            maleta: Fixture.resumos("gloss")
        )

        #expect(fora.contains("Pó"))
        #expect(!fora.contains("Gloss"))
    }

    @Test("Não acusa nada quando o texto só cita o que está na maleta")
    func textoLimpo() {
        let fora = ChecagemDeInventario.itensForaDaMaleta(
            emTextos: ["Passe o batom e finalize com o gloss."],
            maleta: Fixture.resumos("batom", "gloss")
        )

        #expect(fora.isEmpty)
    }

    /// "Pó" aparece dentro de "pós-punk", que é palavra do roteiro da Lucy.
    /// Busca por trecho acusaria um produto que ninguém citou.
    @Test("Não confunde nome curto com pedaço de outra palavra")
    func naoAcusaPedacoDePalavra() {
        let fora = ChecagemDeInventario.itensForaDaMaleta(
            emTextos: ["No movimento Afro-Goth resgatamos a maquiagem clown do pós-punk."],
            maleta: Fixture.resumos("gloss")
        )

        #expect(!fora.contains("Pó"))
    }

    @Test("Ignora acento e caixa")
    func semAcentoSemCaixa() {
        let fora = ChecagemDeInventario.itensForaDaMaleta(
            emTextos: ["Use a MASCARA DE CILIOS em tres camadas."],
            maleta: Fixture.resumos("gloss")
        )

        #expect(fora.contains("Máscara de cílios"))
    }
}
