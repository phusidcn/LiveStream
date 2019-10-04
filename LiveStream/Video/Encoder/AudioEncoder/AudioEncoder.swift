//
//  AudioEncoder.swift
//  CameraCapture
//
//  Created by Truong Nguyen on 9/28/19.
//  Copyright © 2019 CPU12015. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

protocol AudioEncoderDelegate: NSObjectProtocol {
    func gotAudioEncodedData(_ data: Data?, timestamp: CMTime, error: Error?)
}

class AudioEncoder: NSObject {
    
    public weak var delegate:AudioEncoderDelegate?
    
    public func encode(_ sampleBuffer : CMSampleBuffer){
    
    }
}
