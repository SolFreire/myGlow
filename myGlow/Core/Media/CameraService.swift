//
//  CameraService.swift
//  myGlow
//

import AVFoundation
import Observation


@MainActor
@Observable
final class CameraService: NSObject {
    enum Estado: Equatable {
        case parada
        case pronta
        case semPermissao
        case falhou(String)
    }

    private(set) var estado: Estado = .parada

    let sessao = AVCaptureSession()
    private let saida = AVCapturePhotoOutput()
    private var continuacao: CheckedContinuation<Data, Error>?

    func iniciar() async {
        guard await autorizar() else {
            estado = .semPermissao
            return
        }
        guard estado != .pronta else {
            retomar()
            return
        }

        do {
            try configurar()
            estado = .pronta
            retomar()
        } catch {
            estado = .falhou(error.localizedDescription)
        }
    }

    func parar() {
        let sessao = sessao
        Task.detached { sessao.stopRunning() }
    }

    func capturar() async throws -> Data {
        guard estado == .pronta else { throw CameraErro.naoEstaPronta }

        return try await withCheckedThrowingContinuation { continuacao in
            self.continuacao = continuacao
            let ajustes = AVCapturePhotoSettings()
            self.saida.capturePhoto(with: ajustes, delegate: self)
        }
    }


    private func retomar() {
        let sessao = sessao
        Task.detached {
            guard !sessao.isRunning else { return }
            sessao.startRunning()
        }
    }

    private func autorizar() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: true
        case .notDetermined: await AVCaptureDevice.requestAccess(for: .video)
        default: false
        }
    }

    private func configurar() throws {
        sessao.beginConfiguration()
        defer { sessao.commitConfiguration() }

        sessao.sessionPreset = .photo

        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                ?? AVCaptureDevice.default(for: .video),
            let entrada = try? AVCaptureDeviceInput(device: camera),
            sessao.canAddInput(entrada),
            sessao.canAddOutput(saida)
        else {
            throw CameraErro.semCamera
        }

        sessao.addInput(entrada)
        sessao.addOutput(saida)
    }
}

extension CameraService: AVCapturePhotoCaptureDelegate {
    nonisolated func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        let resultado: Result<Data, Error> = if let error {
            .failure(error)
        } else if let dados = photo.fileDataRepresentation() {
            .success(dados)
        } else {
            .failure(CameraErro.semImagem)
        }

        Task { @MainActor [weak self] in
            guard let self, let continuacao else { return }
            self.continuacao = nil
            continuacao.resume(with: resultado)
        }
    }
}

enum CameraErro: Error, LocalizedError {
    case semCamera
    case semImagem
    case naoEstaPronta

    var errorDescription: String? {
        switch self {
        case .semCamera: "Não encontrei uma câmera disponível neste aparelho."
        case .semImagem: "A foto não pôde ser processada."
        case .naoEstaPronta: "A câmera ainda não está pronta."
        }
    }
}
