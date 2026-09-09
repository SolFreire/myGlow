//
//  CameraModel.swift
//  myGlow
//
//  Created by marquiros on 03/09/26.
//

import AVFoundation
import SwiftUI
import Photos

@Observable
final class CameraModel {
    private let camera = CameraService()
    var previewImage: Image?
    var photoToken: PhotoData?
    var selectedZoom: CGFloat = 1
    var cameraTimer = 0
    var countdown: Int?
    
    init() {        
        Task {
            await handleCameraPreviews()
        }
        
        Task {
            await handleCameraPhotos()
        }
        
    }
    
    func handleCameraPreviews() async {
        let imageStream = camera.previewStream
            .map { $0.image }
        
        for await image in imageStream {
            Task { @MainActor in
                self.previewImage = image
            }
        }
    }

    func handleCameraPhotos() async {
        let unpackedPhotoStream = camera.photoStream
            .compactMap { self.unpackPhoto($0) }
        
        for await photoData in unpackedPhotoStream {
            Task { @MainActor in
                self.photoToken = photoData
            }
        }
    }
    
    func startCamera() async {
        await camera.start()
    }
    func stopCamera() {
        camera.stop()
    }

    func pausePreview() {
        camera.isPreviewPaused = true
    }

    func resumePreview() {
        camera.isPreviewPaused = false
    }
    
    private func unpackPhoto(_ photo: AVCapturePhoto) -> PhotoData? {
         guard let cgImage = photo.cgImageRepresentation(),
               let metadataOrientation = photo.metadata[String(kCGImagePropertyOrientation)] as? UInt32,
               let cgImageOrientation = CGImagePropertyOrientation(rawValue: metadataOrientation)
         else { return nil }

         let imageOrientation = UIImage.Orientation(cgImageOrientation)
         let image = Image(uiImage: UIImage(cgImage: cgImage, scale: 1, orientation: imageOrientation))

         return PhotoData(image: image)
     }
 
        
    var timerLabel: String {
        cameraTimer == 0 ? "Off" : "\(cameraTimer)s"
    }
    
    func changeCameraTimer() {
        switch cameraTimer {
        case 0:
            cameraTimer = 3
            
        case 3:
            cameraTimer = 5
            
        case 5:
            cameraTimer = 10
            
        default:
            cameraTimer = 0
        }
    }
    
    func selectZoom(_ value: CGFloat) {
        selectedZoom = value
        
        if camera.isUsingFrontCaptureDevice {
            camera.setZoom(factor: value)
            return
        }
        
        switch value {
        case 0.5:
            camera.selectBackCamera(lens: .ultraWide)
        case 1:
            camera.selectBackCamera(lens: .wide)
            camera.setZoom(factor: 1)
        case 2:
            camera.setZoom(factor: 2)
        default:
            break
        }
    }
    
    func startCameraTimer() {
        guard cameraTimer > 0 else {
            camera.takePhoto()
            return
        }
        
        countdown = cameraTimer
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self, let current = self.countdown else {
                timer.invalidate()
                return
            }
            
            if current <= 1 {
                timer.invalidate()
                self.countdown = nil
                self.camera.takePhoto()
            } else {
                self.countdown = current - 1
            }
        }
        
    }
    
    var flashModeIcon: String {
        camera.flashModeIcon
    }

    func toggleFlash() {
        camera.toggleFlash()
    }

    func switchCamera() {
        camera.switchCaptureDevice()
    }
    
    func clearPhoto() {
        photoToken = nil
    }
    
}


fileprivate extension CIImage {
    private static let ciContext = CIContext()
    
    var image: Image? {
        guard let cgImage = CIImage.ciContext.createCGImage(self, from: self.extent) else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
}


fileprivate extension UIImage.Orientation {
    
    init(_ cgImageOrientation: CGImagePropertyOrientation) {
        switch cgImageOrientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        }
    }
}

struct PhotoData {
    var image: Image
}
