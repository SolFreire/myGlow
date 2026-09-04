//
//  CameraService.swift
//  myGlow
//

import AVFoundation
import UIKit

@Observable
class CameraService: NSObject {
    
    private let captureSession = AVCaptureSession()
    
    private var isCaptureSessionConfigured = false
    private var deviceInput: AVCaptureDeviceInput?
    private var photoOutput: AVCapturePhotoOutput?
    var flashMode: AVCaptureDevice.FlashMode = .off
    
    private var videoOutput: AVCaptureVideoDataOutput?
    private var sessionQueue: DispatchQueue!
    
    private var allCaptureDevices: [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera, .builtInDualCamera, .builtInDualWideCamera, .builtInUltraWideCamera, .builtInWideAngleCamera, .builtInDualWideCamera], mediaType: .video, position: .unspecified).devices
    }
    
    private var frontCaptureDevices: [AVCaptureDevice] {
        allCaptureDevices
            .filter { $0.position == .front }
    }
    
    private var backCaptureDevices: [AVCaptureDevice] {
        allCaptureDevices
            .filter { $0.position == .back }
    }
    
    private var captureDevices: [AVCaptureDevice] {
        var devices = [AVCaptureDevice]()
        if let backDevice = backCaptureDevices.first {
            devices += [backDevice]
        }
        if let frontDevice = frontCaptureDevices.first {
            devices += [frontDevice]
        }
        return devices
    }
    
    private var availableCaptureDevices: [AVCaptureDevice] {
        captureDevices
            .filter( { $0.isConnected } )
            .filter( { !$0.isSuspended } )
    }
    
    private var captureDevice: AVCaptureDevice? {
        didSet {
            guard let captureDevice = captureDevice else { return }
            sessionQueue.async {
                self.updateSessionForCaptureDevice(captureDevice)
            }
        }
    }
    
    var isRunning: Bool {
        captureSession.isRunning
    }
    
    var isUsingFrontCaptureDevice: Bool {
        guard let captureDevice = captureDevice else { return false }
        return frontCaptureDevices.contains(captureDevice)
    }
    
    var isUsingBackCaptureDevice: Bool {
        guard let captureDevice = captureDevice else { return false }
        return backCaptureDevices.contains(captureDevice)
    }
    
    private var addToPhotoStream: ((AVCapturePhoto) -> Void)?
    
    @ObservationIgnored
    lazy var photoStream: AsyncStream<AVCapturePhoto> = {
        AsyncStream { continuation in
            addToPhotoStream = { photo in
                continuation.yield(photo)
            }
        }
    }()
    
    var isPreviewPaused = false
    
    private var addToPreviewStream: ((CIImage) -> Void)?
    
    @ObservationIgnored
    var previewStream: AsyncStream<CIImage> {
        AsyncStream { continuation in
            addToPreviewStream = { ciImage in
                if !self.isPreviewPaused {
                    continuation.yield(ciImage)
                }
            }
        }
    }
    
    
    override init() {
        super.init()
        captureSession.sessionPreset = .low
        sessionQueue = DispatchQueue(label: "session queue")
        captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera,
                                                for: .video,
                                                position: .front) ?? availableCaptureDevices.first
        
    }
    
    func start() async {
        let authorized = await checkAuthorization()
        guard authorized else {
            print("Camera access was not authorized.")
            return
        }
        
        if isCaptureSessionConfigured {
            if !captureSession.isRunning {
                sessionQueue.async { [self] in
                    self.captureSession.startRunning()
                }
            }
            return
        }
        
        sessionQueue.async { [self] in
            self.configureCaptureSession { success in
                guard success else { return }
                self.captureSession.startRunning()
            }
        }
    }
    
    func stop() {
        guard isCaptureSessionConfigured else { return }
        
        if captureSession.isRunning {
            sessionQueue.async {
                self.captureSession.stopRunning()
            }
        }
    }
    
    func switchCaptureDevice() {
        if isUsingFrontCaptureDevice {
            selectBackCamera(lens: .wide)
        } else {
            guard let front = frontCaptureDevices.first else { return }
            captureDevice = front
        }
    }
    
    enum CameraLens {
        case ultraWide
        case wide
    }
    
    func selectBackCamera(lens: CameraLens) {
        let deviceType: AVCaptureDevice.DeviceType
        
        switch lens {
        case .ultraWide:
            deviceType = .builtInUltraWideCamera
            
        case .wide:
            deviceType = .builtInWideAngleCamera
        }
        
        guard let device = AVCaptureDevice.default(
            deviceType,
            for: .video,
            position: .back
        ) else { return }
        
        captureDevice = device
    }
    
    func takePhoto() {
        guard let photoOutput = self.photoOutput else { return }
        
        sessionQueue.async {
            var photoSettings = AVCapturePhotoSettings()
            
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
            }
            
            let isFlashAvailable = self.deviceInput?.device.isFlashAvailable ?? false
            
            photoSettings.flashMode = isFlashAvailable ? self.flashMode : .off
            
            if let previewPhotoPixelFormatType = photoSettings.availablePreviewPhotoPixelFormatTypes.first {
                photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: previewPhotoPixelFormatType]
            }
            photoSettings.photoQualityPrioritization = .balanced
            
            var rotation: CGFloat = 90
            switch UIDevice.current.orientation {
            case .portrait:
                rotation = self.isUsingBackCaptureDevice ? 0 : 180
            case .landscapeLeft:
                rotation = self.isUsingBackCaptureDevice ? 0 : 180
            case .landscapeRight:
                rotation = self.isUsingBackCaptureDevice ? 180 : 0
            case .portraitUpsideDown:
                rotation = self.isUsingBackCaptureDevice ? 180 : 0
            default:
                break
            }
            
            if let photoOutputVideoConnection = photoOutput.connection(with: .video) {
                photoOutputVideoConnection.videoRotationAngle = rotation
            }
            
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        }
    }
    
    
    private func updateSessionForCaptureDevice(_ captureDevice: AVCaptureDevice) {
        guard isCaptureSessionConfigured else { return }
        
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
        
        for input in captureSession.inputs {
            if let deviceInput = input as? AVCaptureDeviceInput {
                captureSession.removeInput(deviceInput)
            }
        }
        
        if let deviceInput = deviceInputFor(device: captureDevice) {
            if !captureSession.inputs.contains(deviceInput), captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
            }
        }
        
        updateVideoOutputConnection()
    }
    
    private func deviceInputFor(device: AVCaptureDevice?) -> AVCaptureDeviceInput? {
        guard let validDevice = device else { return nil }
        do {
            return try AVCaptureDeviceInput(device: validDevice)
        } catch let error {
            print("Error getting capture device input: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func configureCaptureSession(completionHandler: (_ success: Bool) -> Void) {
        
        var success = false
        
        self.captureSession.beginConfiguration()
        
        defer {
            self.captureSession.commitConfiguration()
            completionHandler(success)
        }
        
        guard
            let captureDevice = captureDevice,
            let deviceInput = try? AVCaptureDeviceInput(device: captureDevice)
        else {
            print("Failed to obtain video input.")
            return
        }
        
        let photoOutput = AVCapturePhotoOutput()
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoDataOutputQueue"))
        
        guard captureSession.canAddInput(deviceInput) else {
            print("Unable to add device input to capture session.")
            return
        }
        guard captureSession.canAddOutput(photoOutput) else {
            print("Unable to add photo output to capture session.")
            return
        }
        guard captureSession.canAddOutput(videoOutput) else {
            print("Unable to add video output to capture session.")
            return
        }
        
        captureSession.addInput(deviceInput)
        captureSession.addOutput(photoOutput)
        captureSession.addOutput(videoOutput)
        
        self.deviceInput = deviceInput
        self.photoOutput = photoOutput
        self.videoOutput = videoOutput
        
        photoOutput.maxPhotoQualityPrioritization = .quality
        
        updateVideoOutputConnection()
        
        isCaptureSessionConfigured = true
        
        success = true
    }
    
    var flashModeValue: String {
        switch flashMode {
        case .off:
            return "Desligado"
        case .on:
            return "Ligado"
        case .auto:
            return "Automático"
        default:
            return "Automático"
        }
    }
    
    func setZoom(factor: CGFloat) {
        guard let device = captureDevice else { return }
        
        do {
            try device.lockForConfiguration()
            
            device.videoZoomFactor = min(
                max(factor, device.minAvailableVideoZoomFactor),
                device.maxAvailableVideoZoomFactor
            )
            
            device.unlockForConfiguration()
            
        } catch {
            print("Erro ao aplicar zoom")
        }
    }
    
    private func checkAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("Camera access authorized.")
            return true
        case .notDetermined:
            print("Camera access not determined.")
            sessionQueue.suspend()
            let status = await AVCaptureDevice.requestAccess(for: .video)
            sessionQueue.resume()
            return status
        case .denied:
            print("Camera access denied.")
            return false
        case .restricted:
            print("Camera library access restricted.")
            return false
        default:
            return false
        }
    }
    
    private func updateVideoOutputConnection() {
        if let videoOutput = videoOutput, let videoOutputConnection = videoOutput.connection(with: .video) {
            if videoOutputConnection.isVideoMirroringSupported {
                videoOutputConnection.isVideoMirrored = isUsingFrontCaptureDevice
            }
        }
    }
    
    func toggleFlash() {
        switch flashMode {
        case .off:
            flashMode = .on
            
        case .on:
            flashMode = .auto
            
        case .auto:
            flashMode = .off
            
        @unknown default:
            flashMode = .off
        }
    }
    
    var flashModeIcon: String {
        switch flashMode {
        case .off:
            return "bolt.slash"
            
        case .on:
            return "bolt.fill"
            
        case .auto:
            return "bolt.badge.a"
            
        @unknown default:
            return "bolt.slash"
        }
    }
    
    
}


extension CameraService: AVCapturePhotoCaptureDelegate {
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }
        
        addToPhotoStream?(photo)
    }
    
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = sampleBuffer.imageBuffer else { return }
        
        var rotation: CGFloat = 90
        switch UIDevice.current.orientation {
        case .portrait:
            rotation = isUsingBackCaptureDevice ? 0 : 180
        case .landscapeLeft:
            rotation = isUsingBackCaptureDevice ? 0 : 180
        case .landscapeRight:
            rotation = isUsingBackCaptureDevice ? 0 : 180
        case .portraitUpsideDown:
            rotation = isUsingBackCaptureDevice ? 0 : 180
        default:
            break
        }
        
        if connection.isVideoRotationAngleSupported(rotation) {
            connection.videoRotationAngle = rotation
        }
        addToPreviewStream?(CIImage(cvPixelBuffer: pixelBuffer))
    }
}
