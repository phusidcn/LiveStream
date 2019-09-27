//
//  AVCaptureModule.swift
//  LiveStream
//
//  Created by Thang on 26/9/2019.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import AVFoundation

class AVCaptureModule: NSObject {
    
    // MARK: Public methods
    
    override init() {
        super.init()
        self.setup()
    }
    
    func cameraAuthorizationStatus() -> VideoCaptureModule.CameraUsageStatus {
        return (self.videoCaptureModule?.cameraAuthorizationStatus())!
    }
    
    func requestCameraAuthorization(completionHandler: @escaping (Bool) -> Void) {
        self.videoCaptureModule?.requestCameraAuthorization(completionHandler: { granted in
            completionHandler(granted)
        })
    }
    
    func microphoneAuthorizationStatus() -> AudioCaptureModule.MicrophoneUsageStatus {
        return (self.audioCaptureModule?.microphoneAuthorizationStatus())!
    }
    
    func requestMicrophoneAuthorization(completionHandler: @escaping (Bool) -> Void) {
        self.audioCaptureModule?.requestMicrophoneAuthorization(completionHandler: { granted in
            completionHandler(granted)
        })
    }
    
    func startVideoPreviewSession(completionHandler: @escaping (Error?) -> Void) {
        DispatchQueue(label:"Preview queue").async {
            do {
                try self.videoCaptureModule?.setupDevice()
                try self.audioCaptureModule?.setupDevice()
                try self.setupDeviceInput(videoModule: self.videoCaptureModule!, audioModule: self.audioCaptureModule!)
                try self.setupVideoOutput()
                
                print("Previewing")
            }
            catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
                return
            }
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    func stopVideoPreviewSession() {
        
    }
    
    private var captureSession: AVCaptureSession?
    private var videoCaptureModule: VideoCaptureModule?
    private var audioCaptureModule: AudioCaptureModule?
    
    private var currentCameraInput: CameraLens?
    
    private var videoOutput: AVCaptureVideoDataOutput?
    private var audioOutput: AVCaptureAudioDataOutput?
}

// MARK: Prepare session methods

extension AVCaptureModule {
    
    func setup() {
        self.captureSession = AVCaptureSession()
        self.videoCaptureModule = VideoCaptureModule()
        self.audioCaptureModule = AudioCaptureModule()
    }
    
    func setupDeviceInput(videoModule: VideoCaptureModule, audioModule: AudioCaptureModule) throws {
        guard let session = self.captureSession else {
            throw AVCaptureError.sessionUnavailable
        }
        if let frontCamDevice = videoModule.frontCameraDevice {
            videoModule.frontDeviceInput = try AVCaptureDeviceInput(device: frontCamDevice)
            if session.canAddInput(videoModule.frontDeviceInput!) {
                session.addInput(videoModule.frontDeviceInput!)
            }
            else {
                throw VideoCaptureModule.VideoCaptureError.missingFrontDeviceInput
            }
        } else {
            if let backCamDevice = videoModule.backCameraDevice {
                videoModule.backDeviceInput = try AVCaptureDeviceInput(device: backCamDevice)
                if session.canAddInput(videoModule.backDeviceInput!) {
                    session.addInput(videoModule.backDeviceInput!)
                }
                else {
                    throw VideoCaptureModule.VideoCaptureError.missingBackDeviceInput
                }
            }
            else {
                throw VideoCaptureModule.VideoCaptureError.invalidInput
            }
        }
        if let audioDevice = audioModule.audioDevice {
            audioModule.audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            if session.canAddInput(audioModule.audioDeviceInput!) {
                session.addInput(audioModule.audioDeviceInput!)
            }
            else {
                throw AudioCaptureModule.AudioCaptureError.missingAudioInput
            }
        }
    }
    
    func setupVideoOutput() throws {
        
        guard let captureSession = self.captureSession else {
            throw AVCaptureError.sessionUnavailable
        }
        
        self.videoOutput = AVCaptureVideoDataOutput()
        self.videoOutput!.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange]
        self.videoOutput!.alwaysDiscardsLateVideoFrames = true
        if captureSession.canAddOutput(self.videoOutput!) {
            captureSession.addOutput(self.videoOutput!)
        }
        
        self.audioOutput = AVCaptureAudioDataOutput()
        
        captureSession.startRunning()
    }
    
}

//MARK: Audio, Video Output Delegate
extension AVCaptureModule: AudioCaptureModuleDelegate, VideoModuleDelegate {

    func didCaptureAudioBuffer(_ audioBuffer: CMSampleBuffer) {
        
    }
    
    func didCapturePixelBuffer(_ pixelBuffer: CVPixelBuffer, _ duration: CMTime, _ position: CMTime) {
        
    }
    
}

//MARK: enum
extension AVCaptureModule {
    enum CameraLens {
        case front
        case back
    }
    
    enum AVCaptureError: Error {
        case sessionUnavailable
    }
    
}


