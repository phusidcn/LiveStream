//
//  MediaRecorder.swift
//  LiveStream
//
//  Created by CPU12015 on 10/3/19.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import UIKit
import AVFoundation
import  Photos

class MediaRecorder: NSObject, CanvasMetalViewDelegate, MicrophoneCaptureDelegate  {
    var mediaWriter : MediaFileWriter?
    var isRecording = false
    
    override init() {
        super.init()
        
    }
    
    func startRecording(){
        if !isRecording{
            // Start recording
            isRecording = true
            
            mediaWriter = MediaFIleWriterStore.CreateMediaWriter(mediaType: .MP4)
            if !(mediaWriter?.startWriting() ?? false){
                print("Can'nt start recording")
            }
        }
    }
    
    func stopRecording(){
        if isRecording{
            // Stop recording
            isRecording = false
            
            mediaWriter?.finishWriting(completion: { (url) in
                // Copy into Photos
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url!)
                }) { saved, error in
                    if saved {
                        print("save video successfully")
                    }
                    else{
                        print("save video failed with error \(String(describing: error))")
                    }

                    // You must deelete this file at this url
                    do{
                        try FileManager.default.removeItem(at: url!)
                    }catch{
                        print("Error when remove file")
                    }
                }
            })
        }
    }
    
    func didOutputPixelBuffer(_ pixelBuffer: CVPixelBuffer, _ presentationTimeStamp: CMTime, _ duration: CMTime) {
        var formatDesc: CMVideoFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &formatDesc)
        if formatDesc != nil  {
            var sampleBuffer: CMSampleBuffer?
            var sampleTiming = CMSampleTimingInfo.init(duration: duration, presentationTimeStamp: presentationTimeStamp, decodeTimeStamp: CMTime.invalid)
            CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                     imageBuffer: pixelBuffer,
                                                     formatDescription: formatDesc!,
                                                     sampleTiming: &sampleTiming,
                                                     sampleBufferOut: &sampleBuffer)
            mediaWriter?.videoAppend(sampleBuffer: sampleBuffer!)
        }
    }
    
    func didCaptureAudioBuffer(_ audioBuffer: CMSampleBuffer) {
        mediaWriter?.audioAppend(sampleBuffer: audioBuffer)
    }
    
}
