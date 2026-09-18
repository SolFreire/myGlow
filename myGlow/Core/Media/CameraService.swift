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
    
    private(set) var currentZoom: CGFloat = 1
    private(set) var minimumZoom: CGFloat = 1
    private(set) var maximumZoom: CGFloat = 2
    private(set) var hasUltraWide = false
    private(set) var zoomPresets: [CGFloat] = [1, 2]
    private(set) var isSwitchingCamera = false
    
    private let allowedZoomPresets: [CGFloat] = [0.5, 1, 2]
    
    private var zoomMultiplier: CGFloat = 1
    
    @ObservationIgnored
    private var zoomObservation: NSKeyValueObservation?
    
    private var allCaptureDevices: [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInTrueDepthCamera,
                .builtInTripleCamera,
                .builtInDualCamera,
                .builtInDualWideCamera,
                .builtInUltraWideCamera,
                .builtInWideAngleCamera
            ],
            mediaType: .video,
            position: .unspecified
        ).devices
    }
    
    private var frontCaptureDevices: [AVCaptureDevice] {
        allCaptureDevices.filter { $0.position == .front }
    }
    
    private var backCaptureDevices: [AVCaptureDevice] {
        allCaptureDevices.filter { $0.position == .back }
    }
    
    private func preferredBackCamera() -> AVCaptureDevice? {
        let types: [AVCaptureDevice.DeviceType] = [
            .builtInTripleCamera,
            .builtInDualWideCamera,
            .builtInDualCamera,
            .builtInWideAngleCamera
        ]
        
        for type in types {
            if let device = AVCaptureDevice.default(
                type,
                for: .video,
                position: .back
            ) {
                return device
            }
        }
        
        return nil
    }
    
    private func preferredFrontCamera() -> AVCaptureDevice? {
        AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: .front
        )
    }
    
    private var captureDevices: [AVCaptureDevice] {
        var devices = [AVCaptureDevice]()
        
        if let backDevice = preferredBackCamera() {
            devices.append(backDevice)
        }
        
        if let frontDevice = preferredFrontCamera() {
            devices.append(frontDevice)
        }
        
        return devices
    }
    
    private var availableCaptureDevices: [AVCaptureDevice] {
        captureDevices
            .filter { $0.isConnected }
            .filter { !$0.isSuspended }
    }
    
    private var captureDevice: AVCaptureDevice? {
        didSet {
            guard let captureDevice else { return }
            
            sessionQueue.async {
                self.updateSessionForCaptureDevice(captureDevice)
            }
        }
    }
    
    var isUsingFrontCaptureDevice: Bool {
        captureDevice?.position == .front
    }
    
    var isUsingBackCaptureDevice: Bool {
        captureDevice?.position == .back
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
        
        captureDevice =
            preferredFrontCamera()
            ?? preferredBackCamera()
            ?? availableCaptureDevices.first
    }
    
    deinit {
        zoomObservation?.invalidate()
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
                    captureSession.startRunning()
                }
            }
            return
        }
        
        sessionQueue.async { [self] in
            configureCaptureSession { success in
                guard success else { return }
                captureSession.startRunning()
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
        guard !isSwitchingCamera else { return }
        
        isSwitchingCamera = true
        
        if isUsingFrontCaptureDevice {
            guard let back = preferredBackCamera() else {
                isSwitchingCamera = false
                return
            }
            
            captureDevice = back
        } else {
            guard let front = preferredFrontCamera() else {
                isSwitchingCamera = false
                return
            }
            
            captureDevice = front
        }
    }
    
    enum CameraLens {
        case ultraWide
        case wide
    }
    
    func selectBackCamera(lens: CameraLens) {
        guard isUsingBackCaptureDevice else { return }
        
        switch lens {
        case .ultraWide:
            setZoom(factor: 0.5)
            
        case .wide:
            setZoom(factor: 1)
        }
    }
    
    func takePhoto() {
        guard let photoOutput else { return }
        
        sessionQueue.async {
            var photoSettings = AVCapturePhotoSettings()
            
            if photoOutput.availablePhotoCodecTypes.contains(.hevc) {
                photoSettings = AVCapturePhotoSettings(
                    format: [
                        AVVideoCodecKey: AVVideoCodecType.hevc
                    ]
                )
            }
            
            let isFlashAvailable =
                self.deviceInput?.device.isFlashAvailable ?? false
            
            photoSettings.flashMode =
                isFlashAvailable ? self.flashMode : .off
            
            if let previewPhotoPixelFormatType =
                photoSettings.availablePreviewPhotoPixelFormatTypes.first {
                
                photoSettings.previewPhotoFormat = [
                    kCVPixelBufferPixelFormatTypeKey as String:
                        previewPhotoPixelFormatType
                ]
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
            
            if let connection = photoOutput.connection(with: .video),
               connection.isVideoRotationAngleSupported(rotation) {
                connection.videoRotationAngle = rotation
            }
            
            photoOutput.capturePhoto(
                with: photoSettings,
                delegate: self
            )
        }
    }
    
    private func displayMultiplier(
        for device: AVCaptureDevice
    ) -> CGFloat {
        
        if #available(iOS 18.0, *) {
            let multiplier = device.displayVideoZoomFactorMultiplier
            
            if multiplier > 0 {
                return multiplier
            }
        }
        
        let constituents = device.constituentDevices
        
        guard let wideIndex = constituents.firstIndex(
            where: {
                $0.deviceType == .builtInWideAngleCamera
            }
        ),
        wideIndex > 0 else {
            return 1
        }
        
        let switchFactors =
            device.virtualDeviceSwitchOverVideoZoomFactors
        
        let factorIndex = wideIndex - 1
        
        guard switchFactors.indices.contains(factorIndex) else {
            return 1
        }
        
        let wideFactor = CGFloat(
            truncating: switchFactors[factorIndex]
        )
        
        guard wideFactor > 0 else {
            return 1
        }
        
        return 1 / wideFactor
    }
    
    private func supportedZoomPresets(
        for device: AVCaptureDevice,
        multiplier: CGFloat
    ) -> [CGFloat] {
        
        let containsUltraWide =
            device.deviceType == .builtInUltraWideCamera
            || device.constituentDevices.contains {
                $0.deviceType == .builtInUltraWideCamera
            }
        
        let minimum =
            device.minAvailableVideoZoomFactor * multiplier
        
        let maximum =
            device.maxAvailableVideoZoomFactor * multiplier
        
        let tolerance: CGFloat = 0.01
        
        return allowedZoomPresets.filter { preset in
            
            if preset == 0.5 {
                guard device.position == .back else {
                    return false
                }
                
                guard containsUltraWide else {
                    return false
                }
            }
            
            return preset >= minimum - tolerance
                && preset <= maximum + tolerance
        }
    }
    
    private func updateZoomInformation(
        for device: AVCaptureDevice
    ) {
        let multiplier = displayMultiplier(for: device)
        
        zoomMultiplier = multiplier
        
        let containsUltraWide =
            device.deviceType == .builtInUltraWideCamera
            || device.constituentDevices.contains {
                $0.deviceType == .builtInUltraWideCamera
            }
        
        let presets = supportedZoomPresets(
            for: device,
            multiplier: multiplier
        )
        
        let minZoom = presets.first ?? 1
        let maxZoom = presets.last ?? 1
        
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            hasUltraWide =
                device.position == .back
                && containsUltraWide
            
            minimumZoom = minZoom
            maximumZoom = maxZoom
            zoomPresets = presets
        }
    }
    
    private func applyInitialZoom(
        to device: AVCaptureDevice
    ) {
        let multiplier = displayMultiplier(for: device)
        
        let oneXHardwareZoom: CGFloat = 1 / multiplier
        
        let zoom = min(
            max(
                oneXHardwareZoom,
                device.minAvailableVideoZoomFactor
            ),
            device.maxAvailableVideoZoomFactor
        )
        
        do {
            try device.lockForConfiguration()
            
            device.cancelVideoZoomRamp()
            device.videoZoomFactor = zoom
            
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Erro ao configurar câmera: \(error)")
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.currentZoom = 1
        }
    }
    
    private func observeZoom(
        of device: AVCaptureDevice
    ) {
        zoomObservation?.invalidate()
        
        zoomObservation = device.observe(
            \.videoZoomFactor,
            options: [.new]
        ) { [weak self] observedDevice, _ in
            
            guard let self else { return }
            
            sessionQueue.async {
                guard self.captureDevice === observedDevice else {
                    return
                }
                
                let displayZoom =
                    observedDevice.videoZoomFactor
                    * self.zoomMultiplier
                
                DispatchQueue.main.async {
                    self.currentZoom = displayZoom
                }
            }
        }
    }
    
    private func updateSessionForCaptureDevice(
        _ captureDevice: AVCaptureDevice
    ) {
        guard isCaptureSessionConfigured else {
            DispatchQueue.main.async {
                self.isSwitchingCamera = false
            }
            
            return
        }
        
        captureSession.beginConfiguration()
        
        defer {
            captureSession.commitConfiguration()
            
            DispatchQueue.main.async {
                self.isSwitchingCamera = false
            }
        }
        
        for input in captureSession.inputs {
            if let deviceInput =
                input as? AVCaptureDeviceInput {
                captureSession.removeInput(deviceInput)
            }
        }
        
        guard let newInput =
            deviceInputFor(device: captureDevice) else {
            return
        }
        
        guard captureSession.canAddInput(newInput) else {
            return
        }
        
        captureSession.addInput(newInput)
        
        deviceInput = newInput
        
        updateZoomInformation(for: captureDevice)
        applyInitialZoom(to: captureDevice)
        observeZoom(of: captureDevice)
        updateVideoOutputConnection()
    }
    
    private func deviceInputFor(
        device: AVCaptureDevice?
    ) -> AVCaptureDeviceInput? {
        
        guard let device else {
            return nil
        }
        
        do {
            return try AVCaptureDeviceInput(device: device)
        } catch {
            print(
                "Error getting capture device input: \(error.localizedDescription)"
            )
            return nil
        }
    }
    
    private func configureCaptureSession(
        completionHandler: (_ success: Bool) -> Void
    ) {
        var success = false
        
        captureSession.beginConfiguration()
        
        defer {
            captureSession.commitConfiguration()
            completionHandler(success)
        }
        
        guard
            let captureDevice,
            let deviceInput = try? AVCaptureDeviceInput(
                device: captureDevice
            )
        else {
            print("Failed to obtain video input.")
            return
        }
        
        let photoOutput = AVCapturePhotoOutput()
        
        captureSession.sessionPreset = .photo
        
        let videoOutput = AVCaptureVideoDataOutput()
        
        videoOutput.setSampleBufferDelegate(
            self,
            queue: DispatchQueue(
                label: "VideoDataOutputQueue"
            )
        )
        
        guard captureSession.canAddInput(deviceInput) else {
            print(
                "Unable to add device input to capture session."
            )
            return
        }
        guard captureSession.canAddOutput(photoOutput) else {
            print(
                "Unable to add photo output to capture session."
            )
            return
        }
        guard captureSession.canAddOutput(videoOutput) else {
            print(
                "Unable to add video output to capture session."
            )
            return
        }
        
        captureSession.addInput(deviceInput)
        captureSession.addOutput(photoOutput)
        captureSession.addOutput(videoOutput)
        
        self.deviceInput = deviceInput
        self.photoOutput = photoOutput
        self.videoOutput = videoOutput
        
        photoOutput.maxPhotoQualityPrioritization = .quality
        
        updateZoomInformation(for: captureDevice)
        applyInitialZoom(to: captureDevice)
        observeZoom(of: captureDevice)
        updateVideoOutputConnection()
        
        isCaptureSessionConfigured = true
        
        success = true
    }
    
    func setZoom(
        factor requestedZoom: CGFloat,
        animated: Bool = false
    ) {
        sessionQueue.async { [weak self] in
            guard
                let self,
                let device = self.captureDevice,
                requestedZoom.isFinite
            else {
                return
            }
            
            let multiplier =
                self.displayMultiplier(for: device)
            
            let presets =
                self.supportedZoomPresets(
                    for: device,
                    multiplier: multiplier
                )
            
            let tolerance: CGFloat = 0.01
            
            guard let zoom = presets.first(
                where: {
                    abs($0 - requestedZoom) < tolerance
                }
            ) else {
                return
            }
            
            let hardwareZoom = min(
                max(
                    zoom / multiplier,
                    device.minAvailableVideoZoomFactor
                ),
                device.maxAvailableVideoZoomFactor
            )
            
            do {
                try device.lockForConfiguration()
                
                device.cancelVideoZoomRamp()
                
                if animated {
                    device.ramp(
                        toVideoZoomFactor: hardwareZoom,
                        withRate: 10
                    )
                } else {
                    device.videoZoomFactor = hardwareZoom
                }
                
                device.unlockForConfiguration()
                
                if !animated {
                    DispatchQueue.main.async {
                        self.currentZoom = zoom
                    }
                }
            } catch {
                print("Erro ao aplicar zoom: \(error)")
            }
        }
    }
    
    private func checkAuthorization() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(
            for: .video
        ) {
        case .authorized:
            print("Camera access authorized.")
            return true
        case .notDetermined:
            print("Camera access not determined.")
            sessionQueue.suspend()
            
            let status =
                await AVCaptureDevice.requestAccess(
                    for: .video
                )
            
            sessionQueue.resume()
            return status
        case .denied:
            print("Camera access denied.")
            return false
        case .restricted:
            print("Camera library access restricted.")
            return false
            
        @unknown default:
            return false
        }
    }
    
    private func updateVideoOutputConnection() {
        guard
            let videoOutput,
            let connection =
                videoOutput.connection(with: .video)
        else {
            return
        }
        
        if connection.isVideoMirroringSupported {
            connection.isVideoMirrored =
                isUsingFrontCaptureDevice
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
    
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            print(
                "Error capturing photo: \(error.localizedDescription)"
            )
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
