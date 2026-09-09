//
//  RotulosUITests.swift
//  myGlowUITests
//

import XCTest


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
