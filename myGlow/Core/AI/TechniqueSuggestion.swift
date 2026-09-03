//
//  TechniqueSuggestion.swift
//  myGlow
//

import Foundation

/// Resumo `Sendable` de um item da maleta.
///
/// A camada de IA nunca recebe o `@Model` do SwiftData direto: o `Tool` do
/// Foundation Models precisa ser `Sendable`, e um objeto gerenciado não é.
nonisolated struct ItemResumo: Hashable, Sendable, Identifiable {
    let id: String
    let nome: String
    let categoria: String

    init(_ item: MakeupItem) {
        self.id = item.catalogoID
        self.nome = item.nome
        self.categoria = item.categoria.nome
    }

    init(id: String, nome: String, categoria: String) {
        self.id = id
        self.nome = nome
        self.categoria = categoria
    }
}

/// O que a camada de IA devolve para a `TutorialViewModel`.
nonisolated struct TechniqueSuggestion: Equatable, Sendable {
    /// De onde veio a sugestão. A View não decide nada com isso — é para log e
    /// para a tela de diagnóstico da PoC.
    enum Origem: String, Equatable, Sendable {
        case onDevice
        case regrasEstaticas
    }

    struct Substituicao: Equatable, Sendable, Identifiable {
        let itemAusente: String
        let itemUsado: String
        let comoFazer: String

        var id: String { "\(itemAusente)>\(itemUsado)" }
    }

    struct ItemNaoUtilizado: Equatable, Sendable, Identifiable {
        let item: String
        let motivo: String

        var id: String { item }
    }

    let passos: [String]
    let substituicoes: [Substituicao]
    /// Itens da maleta que a sugestão deliberadamente **não** usou, com o motivo.
    ///
    /// Existe por causa do achado nº 2 da PoC (§14 do levantamento): sem um campo
    /// obrigatório para isso, o modelo trata o inventário como "lista para usar
    /// por completo" e empurra bronzer num visual gótico.
    let itensNaoUtilizados: [ItemNaoUtilizado]
    let curiosidade: String
    /// Produtos citados no texto que não estão na maleta — resultado da checagem
    /// determinística feita depois da geração, a rede de segurança que a PoC pediu.
    let itensForaDaMaleta: [String]
    let origem: Origem
}
