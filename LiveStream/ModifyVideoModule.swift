//
//  ModifyVideoModule.swift
//  LiveStream
//
//  Created by Thang Nguyen Vo Hong on 9/29/19.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import AVFoundation

protocol ModifyVideoModuleDelegate {
    func didCapturePixelBuffer(_ pixelBuffer: CVPixelBuffer, _ position: CMTime, _ duration: CMTime)
}

class ModifyVideoModule: NSObject, VideoCaptureModuleDelegate {
    func didCaptureVideoBuffer(_ videoBuffer: CMSampleBuffer) {
        
    }
    
    
}


