//
//  AVCaptureModule.swift
//  LiveStream
//
//  Created by Thang on 26/9/2019.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import AVFoundation

class AVCaptureModule: NSObject {
    
    init(sessionPreset: AVCaptureSession.Preset? = .high, useCamera: Bool? = true, captureMode: CameraCapture.CameraCaptureColorMode? = .YUV, useMicrophone: Bool? = true) {
        
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
    
//MARK: Variables
    private var captureSession: AVCaptureSession?
    var cameraCapture: CameraCapture?
    var microphoneCapture: MicrophoneCapture?
    private var useCamera: Bool = false
    private var useMicrophone: Bool = false
    private var isRunning: Bool = false
    private var currentCameraInput: CameraCapture.CameraPosition?
    
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
    
//MARK: Prepare
    func prepareCamera(cameraPosition: CameraCapture.CameraPosition? = .back) -> Array<CameraCapture.CameraCaptureError>? {
        let deviceErrorArray = self.cameraCapture?.setupDevice()
        if deviceErrorArray != nil {
            return deviceErrorArray
        }
        var errorArray: Array<CameraCapture.CameraCaptureError> = Array()
        
        do {
            if (cameraPosition == .back) {
                try self.cameraCapture?.addDeviceInput(captureSession: &self.captureSession, captureDevice: self.cameraCapture?.backCaptureDevice)
            }
            if (cameraPosition == .front) {
                try self.cameraCapture?.addDeviceInput(captureSession: &self.captureSession, captureDevice: self.cameraCapture?.frontCaptureDevice)
            }
        }
        catch {
            errorArray.append(error as! CameraCapture.CameraCaptureError)
        }
        
        self.currentCameraInput = cameraPosition
        
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
    
//MARK: Preview
    func startCameraPreviewSession() throws {
        guard self.captureSession != nil else {
            throw AVCaptureError.sessionUnavailable
        }
        if self.isRunning == false {
            self.captureSession!.startRunning()
            self.isRunning = true
        }
    }
    
    func stopCameraPreviewSession() throws {
        guard self.captureSession != nil else {
            throw AVCaptureError.sessionUnavailable
        }
        if self.isRunning == true {
            self.captureSession!.stopRunning()
            self.isRunning = false
            self.cameraCapture = nil
            self.microphoneCapture = nil
            self.captureSession = nil
        }
    }
    
//MARK: Switch camera 
    func switchCamera() throws {
        guard self.captureSession != nil else {
            throw AVCaptureError.sessionUnavailable
        }
        self.captureSession!.beginConfiguration()
        
        func switchToFront() throws {
            guard self.cameraCapture!.captureDeviceInput != nil else {
                throw CameraCapture.CameraCaptureError.missingDeviceInput
            }
            
            guard self.cameraCapture!.frontCaptureDevice != nil else {
                throw CameraCapture.CameraCaptureError.missingFrontDevice
            }
            
            self.captureSession!.removeInput(self.cameraCapture!.captureDeviceInput!)
            
            do {
                try self.cameraCapture?.addDeviceInput(captureSession: &self.captureSession, captureDevice: self.cameraCapture?.frontCaptureDevice)
            }
            catch  {
                throw error
            }
        }
        
        func switchToBack() throws {
            guard self.cameraCapture!.captureDeviceInput != nil else {
                throw CameraCapture.CameraCaptureError.missingDeviceInput
            }
            
            guard self.cameraCapture!.backCaptureDevice != nil else {
                throw CameraCapture.CameraCaptureError.missingBackDevice
            }
            
            self.captureSession!.removeInput(self.cameraCapture!.captureDeviceInput!)
            
            do {
                try self.cameraCapture?.addDeviceInput(captureSession: &self.captureSession, captureDevice: self.cameraCapture?.backCaptureDevice)
            }
            catch  {
                throw error
            }
        }
        
        do {
            switch self.currentCameraInput {
            case .front:
                try switchToBack()
            case .back:
                try switchToFront()
            case .none:
                throw CameraCapture.CameraCaptureError.wtfOperation
            }
        }
        catch {
            throw(error)
        }
        self.captureSession!.commitConfiguration()
    }
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
//                return .high
                return .hd1280x720
            case .medium:
//                return .medium
                return .vga640x480
            case .low:
//                return .low
                return .cif352x288
            }
        }
        
        func width() -> Int {
            switch self {
            case .high:
                return 720
            case .medium:
                return 480
            case .low:
                return 288
            }
        }
        
        func height() -> Int {
            switch self {
            case .high:
                return 1280
            case .medium:
                return 480
            case .low:
                return 352
            }
        }
        
    }
    
    enum AVCaptureError: Error {
        case sessionUnavailable
    }
    
}


