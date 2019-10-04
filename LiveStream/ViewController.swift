//
//  ViewController.swift
//  LiveStream
//
//  Created by Thang on 26/9/2019.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController {
    
    @IBOutlet weak private var previewView: CanvasMetalView!
    
    @IBOutlet weak var toggleButton: UISwitch!
    
    var avCaptureModule: AVCaptureModule?
    var filter : FilterVideo = FilterVideo()
    var mediaRecorder = MediaRecorder()
    var isRecording = false
    
    @IBOutlet weak var recordButton: UIButton!
    
    @IBAction func changeFilter(_ sender: UISwipeGestureRecognizer) {
        filter.changeFilter(sender)
    }
    
    
    @IBAction func Record(_ sender: UIButton) {
        if isRecording{
            // Stop
            isRecording = false
            recordButton.setTitle("Record", for: .normal)
            recordButton.setTitleColor(UIColor.blue, for: .normal)
            mediaRecorder.stopRecording { (url) in
                self.saveFileIntoPhotos(url: url)
            }
        }else{
            // Start
            isRecording = true
            recordButton.setTitle("Stop", for: .normal)
            recordButton.setTitleColor(UIColor.red, for: .normal)
            
            if #available(iOS 11.0, *) {
                mediaRecorder.startRecording(mediaType: .MP4, videoCodecType: .h264, outputSize: CGSize(width: avCaptureModule?.quality?.width() ?? 640, height: avCaptureModule?.quality?.height() ?? 480))
            } else {
                
            }
        }
    }
    @IBAction func toggleFilter(_ sender: Any) {
        filter.videoFilterOn = !filter.videoFilterOn
        filter.videoFilterOnOff()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        avCaptureModule = AVCaptureModule.init(quality: .low, useCamera: true, captureMode: .RGB, useMicrophone: true)
        
        // Do any additional setup after loading the view.
        do {
            avCaptureModule?.requestCameraAuthorization { (Bool) in}
            avCaptureModule?.requestMicrophoneAuthorization { (Bool) in}
            
            _ = avCaptureModule?.prepareCamera()
            _ = avCaptureModule?.prepareMicrophone()
            try avCaptureModule?.startCameraPreviewSession()
            
        
        }
        catch  {
            
        }
        
        recordButton.setTitle("Record", for: .normal)
        recordButton.setTitleColor(UIColor.blue, for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        filter.previewDelegate = previewView
        previewView.filterDelegate = mediaRecorder;
        avCaptureModule?.microphoneCapture?.audioDelegate = mediaRecorder
        avCaptureModule?.cameraCapture?.cameraDelegate = filter
//        previewView.mirroring = true;
        previewView.mirroring = false
        previewView.rotation = .rotate90Degrees
        
        toggleButton.setOn(true, animated: false)
        
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(changeFilter))
        leftSwipeGesture.direction = .left
        previewView.addGestureRecognizer(leftSwipeGesture)
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(changeFilter))
        rightSwipeGesture.direction = .right
        previewView.addGestureRecognizer(rightSwipeGesture)
    }
    
    private func saveFileIntoPhotos(url : URL){
        func saveFile(url : URL){
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { saved, error in
                if saved {
                    print("save video successfully")
                }
                else{
                    print("save video failed with error \(String(describing: error))")
                }
                
                // You must deelete this file at this url
                do{
                    try FileManager.default.removeItem(at: url)
                }catch{
                    print("Error when remove file")
                }
            }
        }
        
        if PHPhotoLibrary.authorizationStatus() != .authorized{
            PHPhotoLibrary.requestAuthorization { (authorizationStatus) in
                if(authorizationStatus == .authorized){
                    saveFile(url: url)
                }else{
                    print("User should authorize this application to access photos data to save this video")
                }
            }
        }else{
            saveFile(url: url)
        }
    }
    
}

