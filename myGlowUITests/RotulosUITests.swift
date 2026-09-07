//
//  RotulosUITests.swift
//  myGlowUITests
//

import XCTest

/// Todo controle chega ao VoiceOver com nome.
///
/// **O que este teste não faz:** dizer o que o VoiceOver lê. A árvore do
/// XCUITest é mais grossa que a do VoiceOver — ela lista elementos marcados com
/// `accessibilityHidden(true)`, então "aparece aqui" não significa "é falado".
/// Conferir a leitura de verdade exige o Accessibility Inspector ou o VoiceOver
/// ligado, à mão.
///
/// O que dá para garantir daqui, e é o que costuma regredir: nenhum **controle**
/// entra na tela sem rótulo, ou com o nome do arquivo de arte no lugar de um
/// nome de gente.
final class RotulosUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func abrirOSalao() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-pularTelaInicial", "YES", "-primeiroUsoConcluido", "YES"]
        app.launch()
        return app
    }

    /// Um rótulo que é o nome do asset (`icone-maleta`) quer dizer que ninguém
    /// nomeou aquele controle e o sistema caiu no nome do arquivo.
    private func conferir(_ app: XCUIApplication, _ tela: String) {
        let controles = app.buttons.allElementsBoundByIndex
        XCTAssertFalse(controles.isEmpty, "\(tela): nenhum botão encontrado")

        for controle in controles {
            let rotulo = controle.label
            XCTAssertFalse(rotulo.isEmpty, "\(tela): botão sem rótulo")
            XCTAssertFalse(
                rotulo.contains("icone-") || rotulo.contains("fundo-") || rotulo.contains("item-"),
                "\(tela): o botão está sendo anunciado como \"\(rotulo)\", que é o nome do arquivo"
            )
        }
    }

    @MainActor
    func testSalaoTemTodosOsControlesNomeados() throws {
        let app = abrirOSalao()
        XCTAssertTrue(app.buttons["Minha maleta"].waitForExistence(timeout: 10))
        conferir(app, "Salão")
    }

    @MainActor
    func testCadastroTemTodosOsControlesNomeados() throws {
        let app = abrirOSalao()
        let maleta = app.buttons["Minha maleta"]
        XCTAssertTrue(maleta.waitForExistence(timeout: 10))
        maleta.tap()

        XCTAssertTrue(app.buttons["Salvar"].waitForExistence(timeout: 10))
        conferir(app, "Cadastro")
    }

    /// Os cartões do catálogo dizem o nome do item e se ele está guardado — é o
    /// que substitui o arrastar para quem não consegue arrastar.
    @MainActor
    func testCartaoDoCatalogoDizNomeEEstado() throws {
        let app = abrirOSalao()
        let maleta = app.buttons["Minha maleta"]
        XCTAssertTrue(maleta.waitForExistence(timeout: 10))
        maleta.tap()

        let clown = app.buttons["Tinta clown"]
        XCTAssertTrue(clown.waitForExistence(timeout: 10))
        XCTAssertTrue(
            ["Na maleta", "Fora da maleta"].contains(clown.value as? String ?? ""),
            "O cartão precisa dizer se o item está guardado; veio \"\(clown.value ?? "nada")\""
        )
    }
}
