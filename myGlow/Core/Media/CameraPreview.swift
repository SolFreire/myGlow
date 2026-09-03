//
//  CameraPreview.swift
//  myGlow
//

import AVFoundation
import SwiftUI


struct CameraPreview: UIViewRepresentable {
    let sessao: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.camadaDePreview.session = sessao
        view.camadaDePreview.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.camadaDePreview.session = sessao
    }

    final class PreviewView: UIView {
        override static var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }

        var camadaDePreview: AVCaptureVideoPreviewLayer {
            layer as! AVCaptureVideoPreviewLayer
        }
    }
}
