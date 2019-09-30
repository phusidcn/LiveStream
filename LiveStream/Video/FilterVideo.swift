//
//  ModifyVideoModule.swift
//  LiveStream
//
//  Created by Thang Nguyen Vo Hong on 9/29/19.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import AVFoundation

protocol FilterVideoDelegate {
    func didCapturePixelBuffer(_ pixelBuffer: CVPixelBuffer, _ presentationTimeStamp: CMTime, _ duration: CMTime)
}

class FilterVideo: NSObject, CameraCaptureDelegate {
    
    func didCaptureCameraBuffer(_ videoBuffer: CMSampleBuffer) {
        
    }
    
}


