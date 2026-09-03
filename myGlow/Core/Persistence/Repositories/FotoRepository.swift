//
//  FotoRepository.swift
//  myGlow
//

import Foundation

/// As fotos ficam no app, já achatadas com a moldura da subcultura. Exportar
/// para o rolo da câmera é uma ação separada e opcional (`PhotoLibraryService`).
protocol FotoRepository: Sendable {
    func todas() async throws -> [FotoSalva]
    @discardableResult
    func salvar(dados: Data, subcultura: Subcultura) async throws -> FotoSalva
    func apagar(_ foto: FotoSalva) async throws
}
