//
//  AudioCaptureModule.swift
//  LiveStream
//
//  Created by Thang on 27/9/2019.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import Foundation
import AVFoundation

protocol AudioCaptureModuleDelegate {
    func didCaptureAudioBuffer(_ audioBuffer: CMSampleBuffer)
}

class AudioCaptureModule: NSObject {
    
    var audioDevice: AVCaptureDevice?
    var audioDeviceInput: AVCaptureDeviceInput?
    var audioDelegate: AudioCaptureModuleDelegate?

    func microphoneAuthorizationStatus() -> MicrophoneUsageStatus {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            return .MicrophoneUsageAllowed

        case .notDetermined:
            return .MicrophoneUsageNotDetermined

        case .denied:
            return .MicrophoneUsageDenied

        case .restricted:
            return .MicrophoneUsageRestricted

        @unknown default:
            print("Unknown microphone authorization error")
            return .MicrophoneUsageUnknown
        }
    }
    
    func requestMicrophoneAuthorization(completionHandler: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            completionHandler(granted)
        }
    }
    
    func setupDevice() {
        
    }
    
}

//MARK: AudioDataOutputSampleBufferDelegate
extension AudioCaptureModule: AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        audioDelegate?.didCaptureAudioBuffer(sampleBuffer)
    }
}


//MARK: enum
extension AudioCaptureModule {
    
    enum MicrophoneUsageStatus {
        case MicrophoneUsageAllowed
        case MicrophoneUsageNotDetermined
        case MicrophoneUsageDenied
        case MicrophoneUsageRestricted
        case MicrophoneUsageUnknown
    }

    enum AudioCaptureError: Error {
        case missingAudioInput
    }
}
