//
//  SwiftDataFotoRepository.swift
//  myGlow
//

import Foundation
import SwiftData

@MainActor
final class SwiftDataFotoRepository: FotoRepository {
    private let contexto: ModelContext

    init(contexto: ModelContext) {
        self.contexto = contexto
    }

    func todas() async throws -> [FotoSalva] {
        try contexto.fetch(
            FetchDescriptor<FotoSalva>(sortBy: [SortDescriptor(\.criadaEm, order: .reverse)])
        )
    }

    @discardableResult
    func salvar(dados: Data, subcultura: Subcultura) async throws -> FotoSalva {
        let foto = FotoSalva(subcultura: subcultura, dados: dados)
        contexto.insert(foto)
        try contexto.save()
        return foto
    }

    func apagar(_ foto: FotoSalva) async throws {
        contexto.delete(foto)
        try contexto.save()
    }
}
