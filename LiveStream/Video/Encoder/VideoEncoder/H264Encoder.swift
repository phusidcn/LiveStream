//
//  H264Encoder.swift
//  LiveStream
//
//  Created by Thang Nguyen Vo Hong on 9/29/19.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import AVFoundation
import VideoToolbox

protocol H264EncoderDelegate {
    func didOutputH264EncodedBuffer(_ videoBuffer: CMSampleBuffer)
}


class H264Encoder: NSObject {
    
    override init() {
        self.frameCount = 0
        self.encodingQueue = DispatchQueue.global(qos: .default)
        super.init()
        
    }
    
    func setup(quality: AVCaptureModule.CaptureQuality ) {
        let width = quality.width()
        let height = quality.height()
        let status: OSStatus = VTCompressionSessionCreate(allocator: nil,
                                                          width: Int32(width),
                                                          height: Int32(height),
                                                          codecType: kCMVideoCodecType_H264,
                                                          encoderSpecification: nil,
                                                          imageBufferAttributes: nil,
                                                          compressedDataAllocator: nil,
                                                          outputCallback: outputCallback,
                                                          refcon: Unmanaged.passUnretained(self).toOpaque(),
                                                          compressionSessionOut: &self.encodingSession)
        if (status != 0) {
            print("Can't create H.264 session")
            return
        }
        
        VTSessionSetProperty(self.encodingSession!, key: kVTCompressionPropertyKey_RealTime, value: kCFBooleanTrue)
        VTSessionSetProperty(self.encodingSession!, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Baseline_AutoLevel)
        
        var fps = 30
        let fpsRef = CFNumberCreate(kCFAllocatorDefault, .intType , &fps)
        VTSessionSetProperty(self.encodingSession!, key: kVTCompressionPropertyKey_ExpectedFrameRate, value: fpsRef)
        
        var intervalDuration = 2.0
        let intervalDurationRef = CFNumberCreate(kCFAllocatorDefault, .doubleType, &intervalDuration)
        VTSessionSetProperty(self.encodingSession!, key: kVTCompressionPropertyKey_MaxKeyFrameIntervalDuration, value: intervalDurationRef)
        
        var bitRate = width * height * 3 * 4 * 8
        let bitRateRef = CFNumberCreate(kCFAllocatorDefault, .sInt32Type, &bitRate)
        VTSessionSetProperty(self.encodingSession!, key: kVTCompressionPropertyKey_AverageBitRate, value: bitRateRef)
        
        var bitRateLimit = width * height * 3 * 4
        let bitRateLimitRef = CFNumberCreate(kCFAllocatorDefault, .sInt32Type, &bitRateLimit)
        VTSessionSetProperty(self.encodingSession!, key: kVTCompressionPropertyKey_DataRateLimits, value: bitRateLimitRef)
        
        VTCompressionSessionPrepareToEncodeFrames(self.encodingSession!)
    }
    
    func encode(_ pixelBuffer: CVPixelBuffer, _ presentationTimeStamp: CMTime, _ duration: CMTime) {
        self.encodingQueue?.async {
            var flags : VTEncodeInfoFlags = []
            let status: OSStatus = VTCompressionSessionEncodeFrame(self.encodingSession!,
                                                                   imageBuffer: pixelBuffer,
                                                                   presentationTimeStamp: presentationTimeStamp,
                                                                   duration: duration,
                                                                   frameProperties: nil,
                                                                   sourceFrameRefcon: nil,
                                                                   infoFlagsOut: &flags)
            if status != noErr {
                print("H264 Encode failed with ", status);
                VTCompressionSessionInvalidate(self.encodingSession!);
                self.encodingSession = nil
                return;
            }
        }
    }
    
    func stopEncode() {
        self.encodingQueue?.async {
            VTCompressionSessionCompleteFrames(self.encodingSession!, untilPresentationTimeStamp: CMTime.invalid)
            VTCompressionSessionInvalidate(self.encodingSession!)
            self.encodingSession = nil
        }
    }
    
    var delegate: H264EncoderDelegate?
    private var outputCallback: VTCompressionOutputCallback = {
        (outputCallbackRefCon: UnsafeMutableRawPointer?, sourceFrameRefCon: UnsafeMutableRawPointer?,
        status: OSStatus, infoFlags: VTEncodeInfoFlags, sampleBuffer: CMSampleBuffer?) in
        guard
            let refcon: UnsafeMutableRawPointer = outputCallbackRefCon,
            let sampleBuffer: CMSampleBuffer = sampleBuffer, status == noErr else {
            return
        }
        let encoder: H264Encoder = Unmanaged<H264Encoder>.fromOpaque(refcon).takeUnretainedValue()

        encoder.delegate?.didOutputH264EncodedBuffer(sampleBuffer)
    }
    private var frameCount: Int64
    private var encodingSession: VTCompressionSession?
    private var encodingQueue: DispatchQueue?
}
