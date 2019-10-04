//
//  H264Encode.swift
//  CameraCapture
//
//  Created by Truong Nguyen on 9/27/19.
//  Copyright © 2019 CPU12015. All rights reserved.
//

import UIKit
import AVFoundation
import VideoToolbox

fileprivate var NALUHeader: [UInt8] = [0, 0, 0, 1]

func compressionOutputCallback(outputCallbackRefCon: UnsafeMutableRawPointer?,
                               sourceFrameRefCon: UnsafeMutableRawPointer?,
                               status: OSStatus,
                               infoFlags: VTEncodeInfoFlags,
                               sampleBuffer: CMSampleBuffer?) -> Swift.Void
{
    var encoderData = Data()
    
    guard status == noErr else {
        print("error: \(status)")
        return
    }
    
    if infoFlags == .frameDropped {
        print("frame dropped")
        return
    }
    
    guard let sampleBuffer = sampleBuffer else {
        print("sampleBuffer is nil")
        return
    }
    
    if CMSampleBufferDataIsReady(sampleBuffer) != true {
        print("sampleBuffer data is not ready")
        return
    }
    
    let encoder: H264Encoder = Unmanaged.fromOpaque(outputCallbackRefCon!).takeUnretainedValue()
    
    if let attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, createIfNecessary: true) {
        
        let rawDic: UnsafeRawPointer = CFArrayGetValueAtIndex(attachments, 0)
        let dic: CFDictionary = Unmanaged.fromOpaque(rawDic).takeUnretainedValue()
        
        // If not contains means it's an IDR frame
        let keyFrame = !CFDictionaryContainsKey(dic, Unmanaged.passUnretained(kCMSampleAttachmentKey_NotSync).toOpaque())
        
        if keyFrame {
            // print("IDR frame")
            
            // sps
            let format = CMSampleBufferGetFormatDescription(sampleBuffer)
            var spsSize: Int = 0
            var spsCount: Int = 0
            var nalHeaderLength: Int32 = 0
            var sps: UnsafePointer<UInt8>?
            var status: OSStatus
            
            status = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format!,
                                                                        parameterSetIndex: 0,
                                                                        parameterSetPointerOut: &sps,
                                                                        parameterSetSizeOut: &spsSize,
                                                                        parameterSetCountOut: &spsCount,
                                                                        nalUnitHeaderLengthOut: &nalHeaderLength)
            if status == noErr {
                //                print("sps: \(String(describing: sps)), spsSize: \(spsSize), spsCount: \(spsCount), NAL header length: \(nalHeaderLength)")
                //
                // pps
                var ppsSize: Int = 0
                var ppsCount: Int = 0
                var pps: UnsafePointer<UInt8>?
                
                if CMVideoFormatDescriptionGetH264ParameterSetAtIndex(format!,
                                                                      parameterSetIndex: 1,
                                                                      parameterSetPointerOut: &pps,
                                                                      parameterSetSizeOut: &ppsSize,
                                                                      parameterSetCountOut: &ppsCount,
                                                                      nalUnitHeaderLengthOut: &nalHeaderLength) == noErr {
                    // print("pps: \(String(describing: pps)), ppsSize: \(ppsSize), ppsCount: \(ppsCount), NAL header length: \(nalHeaderLength)")
                    
                    let spsData: NSData = NSData(bytes: sps, length: spsSize)
                    let ppsData: NSData = NSData(bytes: pps, length: ppsSize)
                    let headerData: NSData = NSData(bytes: NALUHeader, length: NALUHeader.count)
                    
                    // Add data into packet
                    encoderData.append(headerData as Data)
                    encoderData.append(spsData as Data)
                    encoderData.append(headerData as Data)
                    encoderData.append(ppsData as Data)
                    
                }
            }
            
        }
        
        // Handle frame data
        guard let dataBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) else {
            return
        }
        
        var lengthAtOffset: Int = 0
        var totalLength: Int = 0
        var dataPointer: UnsafeMutablePointer<Int8>?
        if CMBlockBufferGetDataPointer(dataBuffer,
                                       atOffset: 0,
                                       lengthAtOffsetOut: &lengthAtOffset,
                                       totalLengthOut: &totalLength,
                                       dataPointerOut: &dataPointer) == noErr
        {
            var bufferOffset: Int = 0
            let AVCCHeaderLength = 4
            
            while bufferOffset < (totalLength - AVCCHeaderLength)
            {
                var NALUnitLength: UInt32 = 0
                // First four character is NALUnit length
                memcpy(&NALUnitLength, dataPointer?.advanced(by: bufferOffset), AVCCHeaderLength)
                
                // Big endian to host endian. in iOS it's little endian
                NALUnitLength = CFSwapInt32BigToHost(NALUnitLength)
                
                let data: NSData = NSData(bytes: dataPointer?.advanced(by: bufferOffset + AVCCHeaderLength), length: Int(NALUnitLength))
                let headerData: NSData = NSData(bytes: NALUHeader, length: NALUHeader.count)
                
                // Add data into packet
                encoderData.append(headerData as Data)
                encoderData.append(data as Data)
                
                // Move forward to the next NAL Unit
                bufferOffset += Int(AVCCHeaderLength)
                bufferOffset += Int(NALUnitLength)
            }
        }
        encoder.delegate?.gotVideoEncodedData(encoderData, timestamp: CMSampleBufferGetPresentationTimeStamp(sampleBuffer))
    }
}


class H264Encoder: VideoEncoder {
    
    var compressionSession: VTCompressionSession?
    let compressionQueue = DispatchQueue(label: "videotoolbox.compression.compression")
    
    override init(_ outputSize: CGSize) {
        super.init(outputSize)
        setup()
    }
    
    override init() {
        super.init()
        setup()
    }
    
    func setup() {
        let status = VTCompressionSessionCreate(allocator: kCFAllocatorDefault,
                                                width: Int32(outputSize.width),
                                                height: Int32(outputSize.height),
                                                codecType:  kCMVideoCodecType_H264,
                                                encoderSpecification: nil,
                                                imageBufferAttributes: nil,
                                                compressedDataAllocator: nil,
                                                outputCallback: compressionOutputCallback,
                                                refcon: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
                                                compressionSessionOut: &compressionSession)
        
        guard let c = compressionSession else {
            print("Error when creating compression session: \(status)")
            return
        }
        
        VTSessionSetProperty(c, key: kVTCompressionPropertyKey_ProfileLevel, value: kVTProfileLevel_H264_Main_AutoLevel)
        VTSessionSetProperty(c, key: kVTCompressionPropertyKey_RealTime, value: true as CFTypeRef)
        VTSessionSetProperty(c, key: kVTCompressionPropertyKey_MaxKeyFrameInterval, value: 10 as CFTypeRef)
        VTSessionSetProperty(c, key: kVTCompressionPropertyKey_AverageBitRate, value: outputSize.width * outputSize.height * 2 * 32 as CFTypeRef)
        VTSessionSetProperty(c, key: kVTCompressionPropertyKey_DataRateLimits, value: [outputSize.width * outputSize.height * 2 * 4, 1] as CFArray)
        
        VTCompressionSessionPrepareToEncodeFrames(c)
    }
    
    override func encode(_ cvImageBuffer: CVImageBuffer, presentationTimestamp: CMTime, duration: CMTime) {
        if compressionSession == nil{
            return;
        }
        VTCompressionSessionEncodeFrame(compressionSession!,
                                        imageBuffer: cvImageBuffer,
                                        presentationTimeStamp: presentationTimestamp,
                                        duration: duration,
                                        frameProperties: nil,
                                        sourceFrameRefcon: nil,
                                        infoFlagsOut: nil)
    }
    
    override func encode(_ sampleBuffer: CMSampleBuffer) {
        if compressionSession == nil{
            return;
        }
        guard let pixelbuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let presentationTimestamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer)
        let duration = CMSampleBufferGetOutputDuration(sampleBuffer)
        
        encode(pixelbuffer, presentationTimestamp: presentationTimestamp, duration: duration)
        
    }
    
    override func stopEncode() {
        guard let compressionSession = compressionSession else {
            return
        }
        
        VTCompressionSessionCompleteFrames(compressionSession, untilPresentationTimeStamp: CMTime.invalid)
        VTCompressionSessionInvalidate(compressionSession)
        self.compressionSession = nil
    }
}
