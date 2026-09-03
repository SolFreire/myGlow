//
//  RoteiroLoader.swift
//  myGlow
//

import Foundation


private final class RoteiroBundleToken {}

enum RoteiroErro: Error, LocalizedError {
    case arquivoNaoEncontrado(String)
    case decodificacaoFalhou(String, underlying: Error)

    var errorDescription: String? {
        switch self {
        case let .arquivoNaoEncontrado(nome):
            "Roteiro \"\(nome).json\" não está no bundle."
        case let .decodificacaoFalhou(nome, erro):
            "Roteiro \"\(nome).json\" não pôde ser lido: \(erro)"
        }
    }
}


nonisolated enum RoteiroLoader {
    static let bundle = Bundle(for: RoteiroBundleToken.self)

    static func nomeDoArquivo(para subcultura: Subcultura) -> String {
        switch subcultura {
        case .gotica: "gotica"
        case .gyaru: "gyaru"
        case .newRomantic: "new-romantic"
        }
    }

    static func carregar(_ subcultura: Subcultura) throws -> Roteiro {
        try decodificar(Roteiro.self, de: nomeDoArquivo(para: subcultura))
    }

    static func carregarTodos() throws -> [Subcultura: Roteiro] {
        try Subcultura.allCases.reduce(into: [:]) { acumulado, subcultura in
            acumulado[subcultura] = try carregar(subcultura)
        }
    }

    static func carregarOnboarding() throws -> RoteiroOnboarding {
        try decodificar(RoteiroOnboarding.self, de: "onboarding")
    }

    private static func decodificar<T: Decodable>(_ tipo: T.Type, de nome: String) throws -> T {
        guard let url = bundle.url(forResource: nome, withExtension: "json") else {
            throw RoteiroErro.arquivoNaoEncontrado(nome)
        }
        do {
            return try JSONDecoder().decode(tipo, from: Data(contentsOf: url))
        } catch {
            throw RoteiroErro.decodificacaoFalhou(nome, underlying: error)
        }
    }
}
