//
//  AVCaptureModule.swift
//  LiveStream
//
//  Created by Thang on 26/9/2019.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import AVFoundation

class AVCaptureModule: NSObject {
    
    override init() {
        super.init()
        self.setup()
    }
    
//MARK: Camera Authorization
    func cameraAuthorizationStatus() -> VideoCaptureModule.CameraUsageStatus {
        return (self.videoCaptureModule?.cameraAuthorizationStatus())!
    }
    
    func requestCameraAuthorization(completionHandler: @escaping (Bool) -> Void) {
        self.videoCaptureModule?.requestCameraAuthorization(completionHandler: { granted in
            completionHandler(granted)
        })
    }
    
//MARK: Microphone Authorization
    func microphoneAuthorizationStatus() -> AudioCaptureModule.MicrophoneUsageStatus {
        return (self.audioCaptureModule?.microphoneAuthorizationStatus())!
    }
    
    func requestMicrophoneAuthorization(completionHandler: @escaping (Bool) -> Void) {
        self.audioCaptureModule?.requestMicrophoneAuthorization(completionHandler: { granted in
            completionHandler(granted)
        })
    }
    
//MARK: Preview Methods
    func startVideoPreviewSession(completionHandler: @escaping (Error?) -> Void) {
        DispatchQueue(label:"Preview queue").async {
            do {
                try self.videoCaptureModule?.setupDevice()
                try self.videoCaptureModule?.setupDeviceInput(captureSession: &self.captureSession)
                self.videoCaptureModule?.setupDeviceOutput()
                
                try self.startCaptureSession()
            }
            catch {
                DispatchQueue.main.async {
                    completionHandler(error)
                }
            }
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    func stopVideoPreviewSession() {
        
    }

//MARK: Record Methods
    func startRecording(completionHandler: @escaping (Error?) -> Void) {
        do {
            //TODO: check whether is previewing
            
            try self.audioCaptureModule?.setupDevice()
            try self.audioCaptureModule?.setupDeviceInput(captureSession: &self.captureSession)
            self.audioCaptureModule?.setupDeviceOutput()
        }
        catch {
            DispatchQueue.main.async {
                completionHandler(error)
            }
        }
        DispatchQueue.main.async {
            completionHandler(nil)
        }
    }
    
    func pauseRecording() {
        
    }
    
    func stopRecording() {
        
    }

//MARK: Variables
    private var captureSession: AVCaptureSession?
    private var videoCaptureModule: VideoCaptureModule?
    private var audioCaptureModule: AudioCaptureModule?
    //FIXME: Where to put this ?????
    private var currentCameraInput: CameraLens?
}

//MARK: Private methods
extension AVCaptureModule {
    
    func setup() {
        self.captureSession = AVCaptureSession()
        self.videoCaptureModule = VideoCaptureModule()
        self.audioCaptureModule = AudioCaptureModule()
    }
    
    func startCaptureSession() throws {
        guard let captureSession = self.captureSession else {
            throw AVCaptureError.sessionUnavailable
        }
        captureSession.startRunning()
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


