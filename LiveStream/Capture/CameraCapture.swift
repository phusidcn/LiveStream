//
//  VideoCaptureModule.swift
//  LiveStream
//
//  Created by Thang on 27/9/2019.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import AVFoundation

protocol CameraCaptureDelegate {
    func didCaptureCameraBuffer(_ videoBuffer: CMSampleBuffer)
}

class CameraCapture: NSObject {
        
//MARK: Variables
    var orientation: CameraOrientation?
    var captureMode: CameraCaptureColorMode?
    
    var frontCaptureDevice: AVCaptureDevice?
    var backCaptureDevice: AVCaptureDevice?
    var captureDeviceInput: AVCaptureDeviceInput?

    static var cameraCaptureQueue = DispatchQueue(label: "Camera Capture Queue")
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
    
//MARK: Setup
    func setup(captureMode: CameraCaptureColorMode? = .RGB) {
        self.captureMode = captureMode
//        self.cameraCaptureQueue = DispatchQueue(label: "Video Capture Queue")
    }
    
    func setupDevice() -> Array<CameraCaptureError>? {
        var errorArray: Array<CameraCaptureError> = Array()
        
        do {
            try setupFrontDevice()
        }
        catch {
            errorArray.append(error as! CameraCapture.CameraCaptureError)
        }
        
        do {
            try setupBackDevice()
        }
        catch {
            errorArray.append(error as! CameraCapture.CameraCaptureError)
        }
        
        if errorArray.count > 0 {
            return errorArray
        }
        return nil
    }
    
    func setupFrontDevice() throws {
        let frontDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
        if frontDevice != nil {
            self.frontCaptureDevice = frontDevice
        }
        else {
            throw CameraCaptureError.missingFrontDevice
        }
    }
    
    func setupBackDevice() throws {
        let backDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
        if backDevice != nil {
            try backDevice!.lockForConfiguration()
            backDevice!.focusMode = .continuousAutoFocus
            backDevice!.unlockForConfiguration()
            self.backCaptureDevice = backDevice
        }
        else {
            throw CameraCaptureError.missingBackDevice
        }
    }
    
    func addDeviceInput(captureSession: inout AVCaptureSession?, captureDevice: AVCaptureDevice?) throws {
        guard captureSession != nil else {
            throw AVCaptureModule.AVCaptureError.sessionUnavailable
        }
        if captureDevice != nil {
            self.captureDeviceInput = try AVCaptureDeviceInput(device:captureDevice!)
            if captureSession!.canAddInput(self.captureDeviceInput!) {
                captureSession!.addInput(self.captureDeviceInput!)
            }
            else {
                throw CameraCaptureError.missingDeviceInput
            }
        }
    }
    
    func setupDeviceOutput(captureSession: inout AVCaptureSession?) throws {
        guard captureSession != nil else {
            throw AVCaptureModule.AVCaptureError.sessionUnavailable
        }
        self.videoOutput = AVCaptureVideoDataOutput()
        self.videoOutput!.setSampleBufferDelegate(self, queue: CameraCapture.cameraCaptureQueue)
        
        if self.captureMode == .YUV {
            self.videoOutput!.videoSettings = [
                                               kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
        }
        if self.captureMode == .RGB {
            self.videoOutput!.videoSettings = [
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
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        print("hahaha")
        self.cameraDelegate?.didCaptureCameraBuffer(sampleBuffer)
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
    
    enum CameraCaptureColorMode {
        case YUV
        case RGB
    }
    
    enum CameraCaptureError: Error {
        case missingFrontDevice
        case missingBackDevice
        case missingDeviceInput
        case missingDeviceOutput
        case wtfOperation
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
