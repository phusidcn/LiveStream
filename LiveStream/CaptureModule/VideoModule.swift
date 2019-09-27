//
//  VideoModule.swift
//  LiveStream
//
//  Created by Thang on 27/9/2019.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import AVFoundation

protocol VideoModuleDelegate {
    func didCapturePixelBuffer(_ pixelBuffer: CVPixelBuffer, _ position: CMTime, _ duration: CMTime)
}

class VideoModule: NSObject, VideoCaptureModuleDelegate {
    
    var videoDelegate: VideoModuleDelegate?
    
    func didCaptureVideoBuffer(_ videoBuffer: CMSampleBuffer) {
        //Duc code
        
//        videoDelegate?.didCapturePixelBuffer(pixelBuffer: CVPixelBuffer, position: CMTime, duration: CMTime)
    }
    
    
}
