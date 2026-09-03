//
//  RepositoriosTests.swift
//  myGlowTests
//

import Foundation
import SwiftData
import Testing
@testable import myGlow

/// Cada suíte segura o próprio `ModelContainer`. Não é detalhe: se o container
/// for temporário, ele é liberado e leva o `mainContext` junto — o teste morre
/// antes de chegar na primeira asserção.
///
/// O Swift Testing cria uma instância nova da suíte por teste, então guardar o
/// container aqui já dá o isolamento limpo entre testes, sem `setUp`/`tearDown`.
@MainActor
private func containerEmMemoria() throws -> ModelContainer {
    try ModelContainer(
        for: Schema([MakeupItem.self, UserProgress.self, FotoSalva.self]),
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
}

@Suite("Maleta em SwiftData")
@MainActor
struct SwiftDataInventoryRepositoryTests {
    private let container: ModelContainer
    private let repo: SwiftDataInventoryRepository

    init() throws {
        container = try containerEmMemoria()
        repo = SwiftDataInventoryRepository(contexto: container.mainContext)
    }

    @Test("Adiciona e recupera")
    func adicionaERecupera() async throws {
        try await repo.adicionar(try #require(CatalogoMaquiagem.item(id: "batom")))

        let itens = try await repo.todos()
        #expect(itens.count == 1)
        #expect(itens.first?.nome == "Batom")
        #expect(itens.first?.categoria == .batom)
    }

    @Test("Adicionar o mesmo item duas vezes não duplica")
    func naoDuplica() async throws {
        let clown = try #require(CatalogoMaquiagem.item(id: "clown"))

        try await repo.adicionar(clown)
        try await repo.adicionar(clown)

        #expect(try await repo.todos().count == 1)
    }

    @Test("Remove pelo id do catálogo")
    func remove() async throws {
        try await repo.adicionar(try #require(CatalogoMaquiagem.item(id: "gloss")))
        try await repo.remover(catalogoID: "gloss")

        #expect(try await repo.todos().isEmpty)
    }

    @Test("Os ids cadastrados são o que a tela de Cadastro desenha")
    func idsCadastrados() async throws {
        for id in ["clown", "pancake", "sombra-roxa"] {
            try await repo.adicionar(try #require(CatalogoMaquiagem.item(id: id)))
        }

        #expect(try await repo.idsCadastrados() == ["clown", "pancake", "sombra-roxa"])
    }
}

@Suite("Álbum de fotos em SwiftData")
@MainActor
struct SwiftDataFotoRepositoryTests {
    private let container: ModelContainer
    private let repo: SwiftDataFotoRepository

    init() throws {
        container = try containerEmMemoria()
        repo = SwiftDataFotoRepository(contexto: container.mainContext)
    }

    @Test("Salva e lista da mais recente para a mais antiga")
    func salvaEOrdena() async throws {
        try await repo.salvar(dados: Data([0x01]), subcultura: .gotica)
        try await Task.sleep(for: .milliseconds(10))
        try await repo.salvar(dados: Data([0x02]), subcultura: .gyaru)

        let fotos = try await repo.todas()
        #expect(fotos.count == 2)
        #expect(fotos.first?.subcultura == .gyaru)
    }

    @Test("Apaga uma foto")
    func apaga() async throws {
        let foto = try await repo.salvar(dados: Data([0x01]), subcultura: .newRomantic)

        try await repo.apagar(foto)

        #expect(try await repo.todas().isEmpty)
    }
}

@Suite("Progresso em SwiftData")
@MainActor
struct SwiftDataProgressRepositoryTests {
    private let container: ModelContainer
    private let repo: SwiftDataProgressRepository

    init() throws {
        container = try containerEmMemoria()
        repo = SwiftDataProgressRepository(contexto: container.mainContext)
    }

    @Test("Cria o progresso na primeira consulta e reaproveita depois")
    func criaUmaVezSo() async throws {
        let primeiro = try await repo.progresso(de: .gyaru)
        let segundo = try await repo.progresso(de: .gyaru)

        #expect(primeiro === segundo)
    }

    @Test("Não marca a mesma etapa duas vezes")
    func etapaSemRepeticao() async throws {
        try await repo.marcarEtapaConcluida("gyaru-pele", em: .gyaru)
        try await repo.marcarEtapaConcluida("gyaru-pele", em: .gyaru)

        #expect(try await repo.progresso(de: .gyaru).etapasConcluidas == ["gyaru-pele"])
    }

    @Test("Conta tutoriais concluídos por subcultura")
    func contaTutoriais() async throws {
        try await repo.marcarTutorialConcluido(.gotica)
        try await repo.marcarTutorialConcluido(.gotica)

        #expect(try await repo.progresso(de: .gotica).tutoriaisConcluidos == 2)
        #expect(try await repo.progresso(de: .gyaru).tutoriaisConcluidos == 0)
    }

    /// Reler pelo mesmo contexto só prova que o objeto em memória mudou — e é
    /// exatamente o objeto que a tela já tem na mão. O que a pessoa sente é a
    /// próxima abertura do app: se a gravação não chegou ao store, a lembrança
    /// conquistada some do salão e a trilha parece não ter contado.
    @Test("A conclusão sobrevive a um contexto novo")
    func conclusaoPersiste() async throws {
        try await repo.marcarTutorialConcluido(.gotica)

        let outroContexto = ModelContext(container)
        let outroRepo = SwiftDataProgressRepository(contexto: outroContexto)

        #expect(try await outroRepo.progresso(de: .gotica).tutoriaisConcluidos == 1)
    }

    @Test("A etapa concluída sobrevive a um contexto novo")
    func etapaPersiste() async throws {
        try await repo.marcarEtapaConcluida("gotica-base", em: .gotica)

        let outroContexto = ModelContext(container)
        let outroRepo = SwiftDataProgressRepository(contexto: outroContexto)

        #expect(try await outroRepo.progresso(de: .gotica).etapasConcluidas == ["gotica-base"])
    }
}
