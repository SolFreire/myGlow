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

    /// O pedido de sugestão em andamento. Passar rápido pelas etapas dispara
    /// `avancar()` várias vezes sem esperar a anterior terminar (cada toque
    /// cria uma `Task` nova) — sem cancelar o pedido velho, cada etapa visitada
    /// empilhava uma geração de IA rodando ao mesmo tempo no aparelho, e a
    /// resposta mais lenta ainda podia sobrescrever `sugestao` por cima da
    /// etapa atual. Cancelar aqui resolve os dois problemas de uma vez: se o
    /// Foundation Models respeitar o cancelamento, a geração em andamento nem
    /// termina de rodar; e mesmo que não respeite, `Task.isCancelled` barra o
    /// resultado tardio de ser aplicado.
    private var tarefaDeSugestao: Task<Void, Never>?

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

    private var sugestaoPronta: TechniqueSuggestion? {
        guard case let .pronta(tecnica) = sugestao else { return nil }
        return tecnica
    }

    /// Verdadeiro quando o índice aponta para a dica, e não para uma fala do
    /// roteiro. Só existe depois da última fala real de uma etapa com sugestão
    /// pronta — nunca desloca o índice das falas reais, então `voltar()` não
    /// precisa de nenhuma mudança: decrementar a partir daqui já leva de volta
    /// à última fala de verdade.
    private var naFalaDeSugestao: Bool {
        guard let etapa = etapaAtual else { return false }
        return indiceFala == etapa.falas.count && sugestaoPronta != nil
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
        naFalaDeSugestao ? .sugestao : (falaAtual?.tipo.estiloDoBalao ?? .padrao)
    }

    /// A `TutorialView` lê isto em vez de `falaAtual?.texto` direto — é o que
    /// permite a dica aparecer sem um `Fala` de verdade por trás dela.
    var textoDoBalao: String {
        naFalaDeSugestao ? (sugestaoPronta?.dica ?? "") : (falaAtual?.texto ?? "")
    }

    var rotuloDaFala: String? {
        if naFalaDeSugestao { return "Dica da \(roteiro.personagem.nome)" }
        guard let fala = falaAtual else { return nil }

        switch fala.tipo.estiloDoBalao {
        case .padrao:
            return roteiro.personagem.nome
        case .passo:
            return numeroDoPasso.map { "Passo \($0)" } ?? roteiro.personagem.nome
        case .contexto:
            return fala.titulo ?? roteiro.subcultura.rotuloDeContexto
        case .sugestao:
            return nil // Fala.Tipo nunca mapeia para .sugestao — branch morto por exaustividade.
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

        // Da última fala real, um avanço a mais leva à dica — só quando ela
        // existe. Se não existir, cai direto no fluxo de conclusão de etapa
        // abaixo, sem parada a mais.
        if indiceFala == etapa.falas.count - 1, sugestaoPronta != nil {
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
        tarefaDeSugestao?.cancel()

        guard let etapa = etapaAtual else { return }

        let faltantes = etapa.itensFaltantes(naMaleta: Set(inventario.map(\.catalogoID)))
        guard !faltantes.isEmpty else {
            sugestao = .ociosa
            return
        }

        sugestao = .carregando
        let inventarioAtual = inventario.map(ItemResumo.init)
        let suggester = suggester

        let tarefa = Task {
            do {
                let resultado = try await suggester.suggestTechnique(for: etapa, inventory: inventarioAtual)
                // Se esta tarefa foi cancelada, uma etapa mais nova já assumiu
                // — a resposta chegou tarde demais e não é mais sobre o que a
                // pessoa está vendo.
                guard !Task.isCancelled else { return }
                self.sugestao = .pronta(resultado)
            } catch is CancellationError {
                // Descartado de propósito.
            } catch let erro as SuggestionError {
                guard !Task.isCancelled else { return }
                self.sugestao = .erro(erro.localizedDescription)
            } catch {
                guard !Task.isCancelled else { return }
                self.sugestao = .erro(error.localizedDescription)
            }
        }
        tarefaDeSugestao = tarefa
        await tarefa.value
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
