//
//  VideoCaptureModule.swift
//  LiveStream
//
//  Created by Thang on 27/9/2019.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import AVFoundation

protocol VideoCaptureModuleDelegate {
    func didCaptureVideoBuffer(_ videoBuffer: CMSampleBuffer)
}

class VideoCaptureModule: NSObject {
        
//MARK: Variables
    var frontCameraDevice: AVCaptureDevice?
    var backCameraDevice: AVCaptureDevice?
    
    var frontDeviceInput: AVCaptureDeviceInput?
    var backDeviceInput: AVCaptureDeviceInput?
    
    var videoQueue: DispatchQueue?
    var videoOutput: AVCaptureVideoDataOutput?
    var videoConnection: AVCaptureConnection?
    
    var videoDelegate: VideoCaptureModuleDelegate?
    
    
//MARK: Authorization
    func cameraAuthorizationStatus() -> CameraUsageStatus {
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
    
    func requestCameraAuthorization(completionHandler: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            completionHandler(granted)
        }
    }
    
//MARK: Setup methods
    func setupDevice() throws {
        let deviceSession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        let deviceMap = deviceSession.devices.compactMap{ $0 }
        guard !deviceMap.isEmpty else {
            throw VideoCaptureError.cameraUnavailable
        }
        for device in deviceMap {
            if device.position == .back {
                self.backCameraDevice = device
                try device.lockForConfiguration()
                device.focusMode = .continuousAutoFocus
                device.unlockForConfiguration()
            }
            if device.position == .front {
                self.frontCameraDevice = device
            }
        }
    }
    
    func setupDeviceInput(captureSession: inout AVCaptureSession?) throws {
        var count = 0
        guard let session = captureSession else {
            throw AVCaptureModule.AVCaptureError.sessionUnavailable
        }
        if let frontCamDevice = self.frontCameraDevice {
            self.frontDeviceInput = try AVCaptureDeviceInput(device: frontCamDevice)
            if session.canAddInput(self.frontDeviceInput!) {
                session.addInput(self.frontDeviceInput!)
                count+=1
            }
            else {
                throw VideoCaptureError.missingFrontDeviceInput
            }
        }
        if let backCamDevice = self.backCameraDevice {
            self.backDeviceInput = try AVCaptureDeviceInput(device: backCamDevice)
            if session.canAddInput(self.backDeviceInput!) {
                session.addInput(self.backDeviceInput!)
                count+=1
            }
            else {
                throw VideoCaptureError.missingBackDeviceInput
            }
        }
        if (count == 0) {
            throw VideoCaptureError.invalidInput
        }
    }
    
    func setupDeviceOutput() {
        self.videoQueue = DispatchQueue(label: "Video Capture Queue")
        
        self.videoOutput = AVCaptureVideoDataOutput()
        self.videoOutput!.setSampleBufferDelegate(self, queue: self.videoQueue)
        self.videoOutput!.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
        self.videoOutput!.alwaysDiscardsLateVideoFrames = true
        
        self.videoConnection = self.videoOutput!.connection(with: .video)
    }
    
}

//MARK: VideoDataOutputSampleBufferDelegate
extension VideoCaptureModule: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        videoDelegate?.didCaptureVideoBuffer(sampleBuffer)
    }
}

//MARK: enum
extension VideoCaptureModule {
    
    enum CameraUsageStatus {
        case CameraUsageAllowed
        case CameraUsageNotDetermined
        case CameraUsageDenied
        case CameraUsageRestricted
        case CameraUsageUnknown
    }
    
    enum VideoCaptureError: Error {
        case missingFrontDeviceInput
        case missingBackDeviceInput
        case invalidInput
        case cameraUnavailable
        case unknownError
    }
}
