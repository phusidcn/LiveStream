//
//  AVCaptureModule.swift
//  LiveStream
//
//  Created by Thang on 26/9/2019.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import AVFoundation

class AVCaptureModule: NSObject {
    
    init(sessionPreset: AVCaptureSession.Preset? = .high, useCamera: Bool? = true, captureMode: CameraCapture.CameraCaptureMode? = .YUV, useMicrophone: Bool? = true) {
        
        super.init()
        
        self.captureSession = AVCaptureSession()
        
        if useCamera == true {
            self.useCamera = true
            self.cameraCapture = CameraCapture()
            self.cameraCapture?.captureMode = captureMode
        }
        
        if useMicrophone == true {
            self.useMicrophone = true
            self.microphoneCapture = MicrophoneCapture()
        }
    }
    
//MARK: Camera Authorization
    func cameraAuthorizationStatus() -> CameraCapture.CameraUsageStatus {
        return (self.cameraCapture?.authorizationStatus())!
    }
    
    func requestCameraAuthorization(completionHandler: @escaping (Bool) -> Void) {
        self.cameraCapture?.requestAuthorization(completionHandler: { granted in
            completionHandler(granted)
        })
    }
    
//MARK: Microphone Authorization
    func microphoneAuthorizationStatus() -> MicrophoneCapture.MicrophoneUsageStatus {
        return (self.microphoneCapture?.microphoneAuthorizationStatus())!
    }
    
    func requestMicrophoneAuthorization(completionHandler: @escaping (Bool) -> Void) {
        self.microphoneCapture?.requestMicrophoneAuthorization(completionHandler: { granted in
            completionHandler(granted)
        })
    }
    
//MARK: Prepare methods
    func prepareCamera() -> Array<CameraCapture.CameraCaptureError> {
        var errorArray : Array<CameraCapture.CameraCaptureError> = Array()
        
        do {
            try self.cameraCapture?.setupDevice()
        }
        catch {
            errorArray.append(error as! CameraCapture.CameraCaptureError)
        }
        
        do {
            try self.cameraCapture?.setupDeviceInput(captureSession: &self.captureSession)
        }
        catch {
            errorArray.append(error as! CameraCapture.CameraCaptureError)
        }
        
        do {
            try self.cameraCapture?.setupDeviceOutput(captureSession: &self.captureSession)
        }
        catch {
            errorArray.append(error as! CameraCapture.CameraCaptureError)
        }
        return errorArray
    }
    
    func prepareMicrophone() -> Array<MicrophoneCapture.MicrophoneCaptureError> {
        var errorArray : Array<MicrophoneCapture.MicrophoneCaptureError> = Array()
        
        do {
            try self.microphoneCapture?.setupDevice()
        }
        catch {
            errorArray.append(error as! MicrophoneCapture.MicrophoneCaptureError)
        }
        
        do {
            try self.microphoneCapture?.setupDeviceInput(captureSession: &self.captureSession)
        }
        catch {
            errorArray.append(error as! MicrophoneCapture.MicrophoneCaptureError)
        }
        
        do {
            try self.cameraCapture?.setupDeviceOutput(captureSession: &self.captureSession)
        }
        catch {
            errorArray.append(error as! MicrophoneCapture.MicrophoneCaptureError)
        }
        return errorArray
    }
    
//MARK: Preview methods
    func startVideoPreviewSession() throws {
        guard self.captureSession != nil else {
            throw AVCaptureError.sessionUnavailable
        }
        self.captureSession!.startRunning()
    }
    
    func stopVideoPreviewSession() throws {
        guard self.captureSession != nil else {
            throw AVCaptureError.sessionUnavailable
        }
        self.captureSession!.stopRunning()
    }

//MARK: Record Methods
    func startRecording(completionHandler: @escaping (Error?) -> Void) {
        do {
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
    private var cameraCapture: CameraCapture?
    private var microphoneCapture: MicrophoneCapture?
    private var useCamera: Bool = false
    private var useMicrophone: Bool = false
    //FIXME: Where to put this ?????
    private var currentCameraInput: CameraCapture.CameraPosition?
}

//MARK: enum
extension AVCaptureModule {
    
    enum CaptureQuality {
        case high
        case medium
        case low
        
        func capturePreset() -> AVCaptureSession.Preset {
            switch self {
            case .high:
                return .high
            case .medium:
                return .medium
            case .low:
                return .low
            }
        }
    }
    
    enum AVCaptureError: Error {
        case sessionUnavailable
    }
    
}


