//
//  H264Encoder.swift
//  LiveStream
//
//  Created by Thang Nguyen Vo Hong on 9/29/19.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import AVFoundation
import VideoToolbox

class H264Encoder: NSObject {
    
    override init() {
        super.init()
        self.encodingQueue = DispatchQueue.global(qos: .default)
        self.count = 0
        
    }
    
    func setup() {
        let width = 480, height = 640
        let status: OSStatus = VTCompressionSessionCreate(allocator: nil, width: Int32(width), height: Int32(height), codecType: kCMVideoCodecType_H264, encoderSpecification: nil, imageBufferAttributes: nil, compressedDataAllocator: nil, outputCallback: outputCallback, refcon: nil, compressionSessionOut: &self.encodingSession)
        if (status != 0) {
            print("Can't create H.264 session")
            return
        }
        
        VTSessionSetProperty(self.encodingSession!, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        VTSessionSetProperty(self.encodingSession!, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Baseline_AutoLevel)
        
        var fps = 24
        let fpsRef = CFNumberCreate(kCFAllocatorDefault, .intType , &fps)
        VTSessionSetProperty(self.encodingSession!, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: fpsRef)
        VTSessionSetProperty(self.encodingSession!, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: fpsRef)
        
        var bitRate = width * height * 3 * 4 * 8
        let bitRateRef = CFNumberCreate(kCFAllocatorDefault, .sInt32Type, &bitRate)
        VTSessionSetProperty(self.encodingSession!, key: kVTCompressionPropertyKey_AverageBitRate, value: bitRateRef)
        
        var bitRateLimit = width * height * 3 * 4
        let bitRateLimitRef = CFNumberCreate(kCFAllocatorDefault, .sInt32Type, &bitRateLimit)
        VTSessionSetProperty(self.encodingSession!, key: kVTCompressionPropertyKey_DataRateLimits, value: bitRateLimitRef)
        
        VTCompressionSessionPrepareToEncodeFrames(self.encodingSession!)
    }
    
    private let outputCallback: VTCompressionOutputCallback = { _, _, status, _, sampleBuffer in
        guard status == noErr, let sampleBuffer = sampleBuffer else {
            return
        }
    }
    private var count: NSInteger?
    private var encodingSession: VTCompressionSession?
    private var encodingQueue: DispatchQueue?
}
