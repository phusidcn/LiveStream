//
//  VideoEncode.swift
//  CameraCapture
//
//  Created by Truong Nguyen on 9/27/19.
//  Copyright © 2019 CPU12015. All rights reserved.
//

import UIKit
import AVFoundation
import VideoToolbox

public protocol VideoEncodeDelegate: NSObjectProtocol{
    func gotVideoEncodedData(_ data:Data, timestamp:CMTime)
}

let MaxVideoOutputSize = CGSize(width: 1080 ,height: 1920)
let MinVideoOutputSize = CGSize(width: 240 ,height: 320)

class VideoEncoder: NSObject {
    public weak var delegate:VideoEncodeDelegate?
    
    var outputSize = CGSize(width: 480 ,height: 640)
    
    public init(_ outputSize: CGSize) {
        if (outputSize.width >= MinVideoOutputSize.width && outputSize.width <= MaxVideoOutputSize.width &&
            outputSize.height >= MinVideoOutputSize.height && outputSize.height <= MaxVideoOutputSize.height)
        {
            self.outputSize = outputSize
        }
        super.init()
    }
    
    public override init() {
        super.init()
    }
    
    public func encode(_ cvImageBuffer: CVImageBuffer, presentationTimestamp: CMTime, duration: CMTime) {
    }
    
    public func encode(_ sampleBuffer: CMSampleBuffer) {
    }
    
    public func stopEncode() {
    }
}
