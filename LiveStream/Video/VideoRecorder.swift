//
//  VideoRecorder.swift
//  LiveStream
//
//  Created by Thang Nguyen Vo Hong on 9/30/19.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import AVFoundation

class VideoRecorder: NSObject, FilterVideoDelegate, MicrophoneCaptureDelegate {
    
    var isRecording: Bool = false
    var videoWriter: AVAssetWriter?
    var videoWriterInput: AVAssetWriterInput?
    var audioWriterInput: AVAssetWriterInput?
    
    func setUpWriter() {
        
        do {
            let outputFileLocation: URL? = videoFileLocation()
            self.videoWriter = try AVAssetWriter(outputURL: outputFileLocation!, fileType: AVFileType.mp4)
            // add video input
            if #available(iOS 11.0, *) {
                self.videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: [
                    AVVideoCodecKey : AVVideoCodecType.h264,
                    AVVideoWidthKey : 720,
                    AVVideoHeightKey : 1280,
                    AVVideoCompressionPropertiesKey : [AVVideoAverageBitRateKey : 2300000]
                ])
            } else {
                self.videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: [
                    AVVideoCodecKey : AVVideoCodecH264,
                    AVVideoWidthKey : 720,
                    AVVideoHeightKey : 1280,
                    AVVideoCompressionPropertiesKey : [AVVideoAverageBitRateKey : 2300000]
                ])
            }
            
            self.videoWriterInput!.expectsMediaDataInRealTime = true
            
            if self.videoWriter!.canAdd(self.videoWriterInput!) {
                self.videoWriter!.add(self.videoWriterInput!)
                print("video input added")
            } else {
                print("no input added")
            }
            
            // add audio input
            self.audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: nil)
            
            self.audioWriterInput!.expectsMediaDataInRealTime = true
            
            if self.videoWriter!.canAdd(audioWriterInput!) {
                self.videoWriter!.add(audioWriterInput!)
                print("audio input added")
            }
            self.videoWriter!.startWriting()
            
        } catch {
            debugPrint(error.localizedDescription)
        }
        
        
    }
    
    func didCapturePixelBuffer(_ pixelBuffer: CVPixelBuffer, _ presentationTime: CMTime, _ duration: CMTime) {
        if self.isRecording != true {
            return
        }
        
        //FIXME: Check startWriting
        self.videoWriter!.startSession(atSourceTime: presentationTime)
        
        if self.canWrite(), (videoWriterInput!.isReadyForMoreMediaData) {
            var formatDesc: CMVideoFormatDescription?
            CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &formatDesc)
            if formatDesc != nil  {
                var sampleBuffer: CMSampleBuffer?
                var sampleTiming = CMSampleTimingInfo.init(duration: duration, presentationTimeStamp: presentationTime, decodeTimeStamp: CMTime.invalid)
                CMSampleBufferCreateReadyWithImageBuffer(allocator: kCFAllocatorDefault,
                                                         imageBuffer: pixelBuffer,
                                                         formatDescription: formatDesc!,
                                                         sampleTiming: &sampleTiming,
                                                         sampleBufferOut: &sampleBuffer)
                self.videoWriterInput!.append(sampleBuffer!)
            }
        }
    }
    
    func didCaptureAudioBuffer(_ audioBuffer: CMSampleBuffer) {
        if self.isRecording != true {
            return
        }
        if self.canWrite(), (audioWriterInput!.isReadyForMoreMediaData) {
            // write audio buffer
            audioWriterInput?.append(audioBuffer)
            //print("audio buffering")
        }
    }
    
    func canWrite() -> Bool {
        return isRecording && videoWriter != nil && videoWriter?.status == .writing
    }
    
    
    //video file location method
    func videoFileLocation() -> URL {
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
        let videoOutputUrl = URL(fileURLWithPath: documentsPath.appendingPathComponent("videoFile")).appendingPathExtension("mov")
        do {
            if FileManager.default.fileExists(atPath: videoOutputUrl.path) {
                try FileManager.default.removeItem(at: videoOutputUrl)
                print("file removed")
            }
        } catch {
            print(error)
        }
        
        return videoOutputUrl
    }
    
    // MARK: Start recording
    func start() {
        //        guard !isRecording else { return }
        //        isRecording = true
        //        sessionAtSourceTime = nil
        //        setUpWriter()
        //        print(isRecording)
        //        print(videoWriter)
        //        if videoWriter.status == .writing {
        //            print("status writing")
        //        } else if videoWriter.status == .failed {
        //            print("status failed")
        //        } else if videoWriter.status == .cancelled {
        //            print("status cancelled")
        //        } else if videoWriter.status == .unknown {
        //            print("status unknown")
        //        } else {
        //            print("status completed")
    }
 
    
    // MARK: Stop recording
    func stop() {
        //        guard isRecording else { return }
        //        isRecording = false
        //        videoWriterInput.markAsFinished()
        //        print("marked as finished")
        //        videoWriter.finishWriting { [weak self] in
        //            self?.sessionAtSourceTime = nil
        //        }
        //        //print("finished writing \(self.outputFileLocation)")
        //        captureSession.stopRunning()
        //        performSegue(withIdentifier: "videoPreview", sender: nil)
    }
}


