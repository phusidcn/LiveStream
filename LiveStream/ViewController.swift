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
    
    var avCaptureModule: AVCaptureModule?
    var filter : FilterVideo = FilterVideo()
    
    @IBAction func changeFilter(_ sender: UISwipeGestureRecognizer) {
        filter.changeFilter(sender)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        avCaptureModule = AVCaptureModule.init(sessionPreset: .low, useCamera: true, captureMode: .RGB, useMicrophone: false)
        
        // Do any additional setup after loading the view.
        do {
            avCaptureModule?.requestCameraAuthorization { (Bool) in}
            //avCaptureModule.requestMicrophoneAuthorization { (Bool) in
            
            //}
            
            _ = avCaptureModule?.prepareCamera()
            try avCaptureModule?.startCameraPreviewSession()
            //avCaptureModule.prepareMicrophone()
        }
        catch  {
            
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        filter.previewDelegate = previewView
        avCaptureModule?.cameraCapture?.cameraDelegate = filter
//        previewView.mirroring = true;
        previewView.mirroring = false
        previewView.rotation = .rotate90Degrees
        
        
        let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(changeFilter))
        leftSwipeGesture.direction = .left
        previewView.addGestureRecognizer(leftSwipeGesture)
        
        let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(changeFilter))
        rightSwipeGesture.direction = .right
        previewView.addGestureRecognizer(rightSwipeGesture)
        
        let upSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(changeFilter))
        upSwipeGesture.direction = .up
        previewView.addGestureRecognizer(upSwipeGesture)
        
        let downSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(changeFilter))
        downSwipeGesture.direction = .down
        previewView.addGestureRecognizer(downSwipeGesture)
    }
}

