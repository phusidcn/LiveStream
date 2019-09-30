//
//  VideoRecorder.swift
//  LiveStream
//
//  Created by Thang Nguyen Vo Hong on 9/30/19.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import AVFoundation

class VideoRecorder: NSObject, FilterVideoDelegate, MicrophoneCaptureDelegate {
    
    var isRecording: Bool = false
    
    func didCapturePixelBuffer(_ pixelBuffer: CVPixelBuffer, _ position: CMTime, _ duration: CMTime) {
        if self.isRecording != true {
            return
        }
    }
    
    func didCaptureAudioBuffer(_ audioBuffer: CMSampleBuffer) {
        if self.isRecording != true {
            return
        }
    }
    
    
}
