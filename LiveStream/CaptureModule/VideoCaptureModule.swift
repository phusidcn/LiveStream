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
        
    var frontCameraDevice: AVCaptureDevice?
    var backCameraDevice: AVCaptureDevice?
    var frontDeviceInput: AVCaptureDeviceInput?
    var backDeviceInput: AVCaptureDeviceInput?
    var videoDelegate: VideoCaptureModuleDelegate?
    
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
        case invalidOperation
        case cameraUnavailable
        case unknownError
    }
}
