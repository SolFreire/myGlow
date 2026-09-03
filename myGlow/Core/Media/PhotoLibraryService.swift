//
//  PhotoLibraryService.swift
//  myGlow
//

import Foundation
import Photos


protocol PhotoLibrarySaving: Sendable {
    func salvarNoRolo(_ dados: Data) async throws
}

nonisolated struct PhotoLibraryService: PhotoLibrarySaving {
    enum Erro: Error, LocalizedError {
        case semPermissao

        var errorDescription: String? {
            "Preciso de permissão para adicionar a foto ao seu rolo da câmera."
        }
    }

    func salvarNoRolo(_ dados: Data) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw Erro.semPermissao }

        try await PHPhotoLibrary.shared().performChanges {
            let pedido = PHAssetCreationRequest.forAsset()
            pedido.addResource(with: .photo, data: dados, options: nil)
        }
    }
}
