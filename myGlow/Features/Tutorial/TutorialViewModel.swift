//
//  TutorialViewModel.swift
//  myGlow
//

import Foundation
import Observation
import SwiftUI

@MainActor
@Observable
final class TutorialViewModel {
    enum EstadoDaSugestao: Equatable {
        case ociosa
        case carregando
        case pronta(TechniqueSuggestion)
        case erro(String)
    }

    let roteiro: Roteiro

    private(set) var indiceEtapa = 0
    private(set) var indiceFala = 0
    private(set) var inventario: [MakeupItem] = []
    private(set) var sugestao: EstadoDaSugestao = .ociosa
    private(set) var terminou = false

    private let suggester: any TechniqueSuggesting
    private let inventarioRepo: any MakeupInventoryRepository
    private let progressoRepo: (any ProgressRepository)?

    init(
        roteiro: Roteiro,
        suggester: any TechniqueSuggesting,
        inventarioRepo: any MakeupInventoryRepository,
        progressoRepo: (any ProgressRepository)? = nil
    ) {
        self.roteiro = roteiro
        self.suggester = suggester
        self.inventarioRepo = inventarioRepo
        self.progressoRepo = progressoRepo
    }

    // MARK: - Estado derivado

    var etapaAtual: TutorialStep? {
        guard indiceEtapa < roteiro.etapas.count else { return nil }
        return roteiro.etapas[indiceEtapa]
    }

    var falaAtual: Fala? {
        guard let etapa = etapaAtual, indiceFala < etapa.falas.count else { return nil }
        return etapa.falas[indiceFala]
    }

    var progresso: Double {
        guard !roteiro.etapas.isEmpty else { return 0 }
        return Double(indiceEtapa) / Double(roteiro.etapas.count)
    }

    var itensFaltantes: [String] {
        guard let etapa = etapaAtual else { return [] }
        return etapa
            .itensFaltantes(naMaleta: Set(inventario.map(\.catalogoID)))
            .map(CatalogoMaquiagem.nome(paraID:))
    }

    /// Onde a personagem fica na cena.
    ///
    /// Sai do estilo do balão, e não do tipo da etapa: na fala normal o balão
    /// atravessa a base e ela fica atrás dele; no passo e no contexto o balão
    /// ocupa a direita, então ela desloca para a esquerda para não ficar por
    /// baixo.
    enum PosicaoDaPersonagem: Equatable {
        case aoCentro
        case aEsquerda
    }

    var posicaoDaPersonagem: PosicaoDaPersonagem {
        estiloDaFala == .padrao ? .aoCentro : .aEsquerda
    }


    var cenaEmFoco: Bool {
        estiloDaFala != .padrao
    }

    var estiloDaFala: BalaoDeFala.Estilo {
        falaAtual?.tipo.estiloDoBalao ?? .padrao
    }


    var rotuloDaFala: String? {
        guard let fala = falaAtual else { return nil }

        switch fala.tipo.estiloDoBalao {
        case .padrao:
            return roteiro.personagem.nome
        case .passo:
            return numeroDoPasso.map { "Passo \($0)" } ?? roteiro.personagem.nome
        case .contexto:
            return fala.titulo ?? roteiro.subcultura.rotuloDeContexto
        }
    }

    /// A posição da etapa entre as etapas práticas — a abertura e o fechamento
    /// não contam, então "Passo 1" é a primeira etapa de maquiagem de verdade.
    var numeroDoPasso: Int? {
        guard let etapa = etapaAtual, etapa.tipo == .passo else { return nil }
        return roteiro.etapas
            .filter { $0.tipo == .passo }
            .firstIndex { $0.id == etapa.id }
            .map { $0 + 1 }
    }

    var ilustracaoAtual: String {
        guard let etapa = etapaAtual, !etapa.ilustracoes.isEmpty else { return ilustracaoDaPersonagem }
        return etapa.ilustracoes[min(indiceFala, etapa.ilustracoes.count - 1)]
    }

    /// A reserva, quando a etapa não declara ilustração. Segue a nomenclatura
    /// que o design usa para os assets: `personagem-lucy`, `personagem-sana`…
    var ilustracaoDaPersonagem: String {
        "personagem-" + roteiro.personagem.nome
            .folding(options: [.diacriticInsensitive], locale: Locale(identifier: "pt_BR"))
            .lowercased()
    }

    // MARK: - Ciclo

    func carregar() async {
        inventario = (try? await inventarioRepo.todos()) ?? []
        await prepararEtapa()
    }

    func avancar() async {
        guard let etapa = etapaAtual else { return }

        if indiceFala + 1 < etapa.falas.count {
            indiceFala += 1
            return
        }

        try? await progressoRepo?.marcarEtapaConcluida(etapa.id, em: roteiro.subcultura)

        guard indiceEtapa + 1 < roteiro.etapas.count else {
            terminou = true
            try? await progressoRepo?.marcarTutorialConcluido(roteiro.subcultura)
            return
        }

        indiceEtapa += 1
        indiceFala = 0
        await prepararEtapa()
    }


    func prepararEtapa() async {
        guard let etapa = etapaAtual else { return }

        let faltantes = etapa.itensFaltantes(naMaleta: Set(inventario.map(\.catalogoID)))
        guard !faltantes.isEmpty else {
            sugestao = .ociosa
            return
        }

        sugestao = .carregando
        do {
            let resultado = try await suggester.suggestTechnique(
                for: etapa,
                inventory: inventario.map(ItemResumo.init)
            )
            sugestao = .pronta(resultado)
        } catch let erro as SuggestionError {
            sugestao = .erro(erro.localizedDescription)
        } catch {
            sugestao = .erro(error.localizedDescription)
        }
    }

    func tentarSugestaoDeNovo() async {
        await prepararEtapa()
    }

    /// Existe algo para trás? É o que decide se o botão de voltar aparece.
    var podeVoltar: Bool {
        indiceEtapa > 0 || indiceFala > 0
    }

    /// Recua uma fala, atravessando a fronteira de etapa quando preciso.
    ///
    /// Não desfaz progresso de propósito: voltar para reler uma curiosidade não
    /// pode zerar etapas que a pessoa já concluiu.
    func voltar() async {
        guard podeVoltar else { return }

        if indiceFala > 0 {
            indiceFala -= 1
            return
        }

        indiceEtapa -= 1
        indiceFala = max(0, (etapaAtual?.falas.count ?? 1) - 1)
        await prepararEtapa()
    }

    func irParaEtapa(_ indice: Int) async {
        guard roteiro.etapas.indices.contains(indice) else { return }
        indiceEtapa = indice
        indiceFala = 0
        await prepararEtapa()
    }
}
