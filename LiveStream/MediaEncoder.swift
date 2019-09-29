//
//  MediaEncoder.swift
//  LiveStream
//
//  Created by Thang Nguyen Vo Hong on 9/29/19.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import AVFoundation

class MediaEncoder: NSObject {
    
}

//MARK: Audio, Video Output Delegate
extension MediaEncoder: AudioCaptureModuleDelegate, ModifyVideoModuleDelegate {
    func didCapturePixelBuffer(_ pixelBuffer: CVPixelBuffer, _ position: CMTime, _ duration: CMTime) {
        
    }

    func didCaptureAudioBuffer(_ audioBuffer: CMSampleBuffer) {
        
    }
    
    
}
