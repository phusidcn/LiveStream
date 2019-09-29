//
//  VideoCaptureModule.swift
//  LiveStream
//
//  Created by Thang on 27/9/2019.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import AVFoundation

protocol CameraCaptureDelegate {
    func didCaptureVideoBuffer(_ videoBuffer: CMSampleBuffer)
}

class CameraCapture: NSObject {
        
//MARK: Variables
    var orientation: CameraOrientation?
    var captureMode: CameraCaptureMode?
    
    var frontCameraDevice: AVCaptureDevice?
    var backCameraDevice: AVCaptureDevice?
    
    var frontDeviceInput: AVCaptureDeviceInput?
    var backDeviceInput: AVCaptureDeviceInput?
    
    var cameraCaptureQueue: DispatchQueue?
    var videoOutput: AVCaptureVideoDataOutput?
    
    var cameraDelegate: CameraCaptureDelegate?
    
//MARK: Authorization
    func authorizationStatus() -> CameraUsageStatus {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return .CameraUsageAllowed
            
        case .notDetermined:
            return .CameraUsageNotDetermined
            
        case .denied:
            return .CameraUsageDenied
            
        case .restricted:
            return .CameraUsageRestricted
        @unknown default:
            print("Unknown camera authorization error")
            return .CameraUsageUnknown
        }
    }
    
    func requestAuthorization(completionHandler: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            completionHandler(granted)
        }
    }
    
//MARK: Setup methods
    func setup(captureMode: CameraCaptureMode? = .YUV) {
        self.captureMode = captureMode
    }
    
    func setupDevice() throws {
        var device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        if device != nil {
            self.frontCameraDevice = device
        }
        
        device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        if device != nil {
            try device!.lockForConfiguration()
            device!.focusMode = .continuousAutoFocus
            device!.unlockForConfiguration()
            self.backCameraDevice = device
        }
    }
    
    func setupDeviceInput(captureSession: inout AVCaptureSession?) throws {
        var count = 0
        guard captureSession != nil else {
            throw AVCaptureModule.AVCaptureError.sessionUnavailable
        }
        if let frontCamDevice = self.frontCameraDevice {
            self.frontDeviceInput = try AVCaptureDeviceInput(device: frontCamDevice)
            if captureSession!.canAddInput(self.frontDeviceInput!) {
                captureSession!.addInput(self.frontDeviceInput!)
                count += 1
            }
        }
        if let backCamDevice = self.backCameraDevice {
            self.backDeviceInput = try AVCaptureDeviceInput(device: backCamDevice)
            if captureSession!.canAddInput(self.backDeviceInput!) {
                captureSession!.addInput(self.backDeviceInput!)
                count += 2
            }
        }
        if count == 0 {
            throw CameraCaptureError.inputUnavailable
        }
        if count == 1 {
            throw CameraCaptureError.missingBackDeviceInput
        }
        if count == 2{
            throw CameraCaptureError.missingFrontDeviceInput
        }
    }
    
    func setupDeviceOutput(captureSession: inout AVCaptureSession?) throws {
        guard captureSession != nil else {
            throw AVCaptureModule.AVCaptureError.sessionUnavailable
        }
        self.cameraCaptureQueue = DispatchQueue(label: "Video Capture Queue")
        
        self.videoOutput = AVCaptureVideoDataOutput()
        self.videoOutput!.setSampleBufferDelegate(self, queue: self.cameraCaptureQueue)
        
        if self.captureMode == .YUV {
            self.videoOutput!.videoSettings = [kCVPixelBufferMetalCompatibilityKey as String: true,
                                               kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
        }
        if self.captureMode == .RGB {
            self.videoOutput!.videoSettings = [kCVPixelBufferMetalCompatibilityKey as String: true,
                                               kCVPixelBufferPixelFormatTypeKey as String:kCVPixelFormatType_32BGRA]
        }
        if captureSession!.canAddOutput(self.videoOutput!) {
            captureSession!.addOutput(self.videoOutput!)
        }
        else {
            throw CameraCaptureError.missingDeviceOutput
        }
    }
    
}

//MARK: VideoDataOutputSampleBufferDelegate
extension CameraCapture: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        self.cameraDelegate?.didCaptureVideoBuffer(sampleBuffer)
    }
}

//MARK: enum
extension CameraCapture {
    
    enum CameraUsageStatus {
        case CameraUsageAllowed
        case CameraUsageNotDetermined
        case CameraUsageDenied
        case CameraUsageRestricted
        case CameraUsageUnknown
    }
    
    enum CameraCaptureMode {
        case YUV
        case RGB
    }
    
    enum CameraCaptureError: Error {
        case missingFrontDeviceInput
        case missingBackDeviceInput
        case inputUnavailable
        case missingDeviceOutput
        case cameraUnavailable
        case unknownError
    }
    
    enum CameraPosition {
        case front
        case back
        
        func orientation() -> CameraOrientation {
            switch self {
            case .front:
                return .landscapeLeft
            case .back:
                return .landscapeRight
            }
        }
    }
    
    enum CameraOrientation {
        case landscapeLeft  //For front camera
        case landscapeRight //For back camera
    }
}
