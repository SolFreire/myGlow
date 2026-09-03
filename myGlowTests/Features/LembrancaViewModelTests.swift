//
//  LembrancaViewModelTests.swift
//  myGlowTests
//

import Testing
@testable import myGlow

/// As lembranças são recompensa por concluir a trilha da personagem, e é esta
/// leitura que decide o que o salão desenha: um falso positivo entrega o objeto
/// sem a pessoa ter feito a trilha, um falso negativo apaga uma conquista que
/// já era dela.
@Suite("Lembranças")
@MainActor
struct LembrancaViewModelTests {
    @Test("No começo, nenhuma lembrança está disponível")
    func tudoBloqueadoNoComeco() async {
        let vm = LembrancaViewModel(progresso: ProgressoEmMemoria())

        await vm.carregar()

        for subcultura in Subcultura.allCases {
            #expect(!vm.desbloqueado(subcultura))
        }
        #expect(vm.concluidas.isEmpty)
    }

    @Test("Concluir uma trilha desbloqueia só a lembrança dela")
    func desbloqueiaSoAConcluida() async throws {
        let progresso = ProgressoEmMemoria()
        try await progresso.marcarTutorialConcluido(.gotica)

        let vm = LembrancaViewModel(progresso: progresso)
        await vm.carregar()

        #expect(vm.desbloqueado(.gotica))
        #expect(!vm.desbloqueado(.gyaru))
        #expect(!vm.desbloqueado(.newRomantic))
    }

    /// Repetir a trilha não pode duplicar nem perder a lembrança: o repositório
    /// conta conclusões, e o salão só quer saber se houve pelo menos uma.
    @Test("Concluir a mesma trilha de novo mantém a lembrança")
    func repetirNaoDesfaz() async throws {
        let progresso = ProgressoEmMemoria()
        try await progresso.marcarTutorialConcluido(.gotica)
        try await progresso.marcarTutorialConcluido(.gotica)

        let vm = LembrancaViewModel(progresso: progresso)
        await vm.carregar()

        #expect(vm.concluidas == [.gotica])
    }

    /// O salão desenha exatamente `concluidas` — se a leitura falhar, some tudo
    /// em vez de aparecer objeto que não foi conquistado.
    @Test("Erro ao ler o progresso não derruba a tela")
    func erroViraMensagem() async {
        let vm = LembrancaViewModel(progresso: ProgressoQueFalha())

        await vm.carregar()

        #expect(vm.erro != nil)
        #expect(vm.concluidas.isEmpty, "Sem progresso legível, nada é desbloqueado")
    }
}

@MainActor
private final class ProgressoQueFalha: ProgressRepository {
    struct Falha: Error {}

    func progresso(de subcultura: Subcultura) async throws -> UserProgress { throw Falha() }
    func marcarEtapaConcluida(_ etapaID: String, em subcultura: Subcultura) async throws {}
    func marcarTutorialConcluido(_ subcultura: Subcultura) async throws {}
}
