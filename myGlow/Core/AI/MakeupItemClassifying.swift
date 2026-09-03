//
//  MakeupItemClassifying.swift
//  myGlow
//

import Foundation

/// Ponto de extensão para o Create ML na v2: fotografar o item e o app sugerir
/// a categoria.
///
/// Na v1 só existe a implementação manual — o cadastro continua sendo seleção no
/// catálogo. Ter o protocolo desde já é o que evita redesenhar a tela depois.
protocol MakeupItemClassifying: Sendable {
    func classificar(imagem: Data) async throws -> CategoriaItem?
}

/// v1: não classifica nada, o preenchimento é manual mesmo.
nonisolated struct ManualEntryClassifier: MakeupItemClassifying {
    func classificar(imagem: Data) async throws -> CategoriaItem? { nil }
}
