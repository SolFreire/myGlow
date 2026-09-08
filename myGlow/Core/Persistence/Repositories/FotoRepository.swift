//
//  FotoRepository.swift
//  myGlow
//

import Foundation


protocol FotoRepository: Sendable {
    func todas() async throws -> [FotoSalva]
    @discardableResult
    func salvar(dados: Data, subcultura: Subcultura) async throws -> FotoSalva
    func apagar(_ foto: FotoSalva) async throws
}
