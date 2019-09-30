//
//  MediaEncoder.swift
//  LiveStream
//
//  Created by Thang on 9/29/19.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import AVFoundation
import Metal

class MediaEncoder: NSObject {
    
    
}

//MARK: Audio, Video Output Delegate
extension MediaEncoder: MicrophoneCaptureDelegate, FilterVideoDelegate {
    func didCapturePixelBuffer(_ pixelBuffer: CVPixelBuffer, _ position: CMTime, _ duration: CMTime) {
    }

    func didCaptureAudioBuffer(_ audioBuffer: CMSampleBuffer) {
        
    }
    
}

