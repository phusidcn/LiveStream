//
//  ViewController.swift
//  LiveStream
//
//  Created by Thang on 26/9/2019.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak private var previewView: CanvasMetalView!
    
    @IBOutlet weak var toggleButton: UISwitch!
    
    var avCaptureModule: AVCaptureModule?
    var filter : FilterVideo = FilterVideo()
    var mediaRecorder = MediaRecorder()
    var isRecording = false
    
    @IBAction func changeFilter(_ sender: UISwipeGestureRecognizer) {
        filter.changeFilter(sender)
    }
    
    
    @IBAction func Record(_ sender: UIButton) {
        if isRecording{
            // Stop
            isRecording = false
            mediaRecorder.stopRecording()
        }else{
            // Start
            isRecording = true
            if #available(iOS 11.0, *) {
                mediaRecorder.startRecording(mediaType: .MP4, videoCodecType: .h264, outputSize: CGSize(width: avCaptureModule?.quality?.width() ?? 640, height: avCaptureModule?.quality?.height() ?? 480))
            } else {
                // Fallback on earlier versions
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
    
    
}

