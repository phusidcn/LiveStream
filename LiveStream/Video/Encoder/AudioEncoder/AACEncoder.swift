import UIKit
import AVFoundation
import AudioToolbox
import CoreAudio

func inInputDataProc(_ inAudioConverter: AudioConverterRef,
                     _ ioNumberDataPackets: UnsafeMutablePointer<UInt32>,
                     _ ioData: UnsafeMutablePointer<AudioBufferList>,
                     _ outDataPacketDescription: UnsafeMutablePointer<UnsafeMutablePointer<AudioStreamPacketDescription>?>?,
                     _ inUserData: UnsafeMutableRawPointer?) -> OSStatus
{
    var ioNumberDataPacket :UnsafeMutablePointer<UInt32>?
    ioNumberDataPacket = ioNumberDataPackets
    let encoder: AACEncoder = Unmanaged.fromOpaque(inUserData!).takeUnretainedValue()
    let requestedPackets : UInt32 = ioNumberDataPackets.pointee
    
    let copiedSamples = encoder.copyPCMSamplesIntoBuffer(ioData)
    if copiedSamples < requestedPackets {
        ioNumberDataPacket = nil
        return -1
    }
    
    ioNumberDataPacket?.pointee = 1
    
    return noErr
}



class AACEncoder: AudioEncoder {
    let encoderQueue = DispatchQueue(label: "AAC Encoder Queue")
    
    private var audioConverter: AudioConverterRef?
    
    private var aacBuffer: UnsafeMutablePointer<UInt8>?
    private var aacBufferSize = 1024
    
    private var pcmBuffer: UnsafeMutablePointer<Int8>?
    private var pcmBufferSize: size_t = 0
    
    
    override init() {
        super.init()
        
        audioConverter = nil
        pcmBuffer = nil
        aacBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: aacBufferSize * MemoryLayout<UInt8>.size)
        
        memset(aacBuffer, 0, aacBufferSize)
        
        delegate = nil
    }
    
    
    deinit {
        AudioConverterDispose(audioConverter!)
        free(aacBuffer)
    }
    
    func setupEncoderFromSampleBuffer(sampleBuffer:CMSampleBuffer)
    {
        guard let inAudioStreamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(CMSampleBufferGetFormatDescription(sampleBuffer)!)
            else
        {
            print("No audio format description")
            return
        }
        
        var outAudioStreamBasicDescription = AudioStreamBasicDescription(mSampleRate: 44100,
                                                                         mFormatID: kAudioFormatMPEG4AAC,
                                                                         mFormatFlags: AudioFormatFlags(MPEG4ObjectID.AAC_LC.rawValue),
                                                                         mBytesPerPacket: 0,
                                                                         mFramesPerPacket: 1024,
                                                                         mBytesPerFrame: 0,
                                                                         mChannelsPerFrame: 1,
                                                                         mBitsPerChannel: 0, mReserved: 0)
        
        var description = [ AudioClassDescription(mType: kAudioEncoderComponentType, mSubType: kAudioFormatMPEG4AAC, mManufacturer: kAppleSoftwareAudioCodecManufacturer) ]
        
        let status = AudioConverterNewSpecific(inAudioStreamBasicDescription, &outAudioStreamBasicDescription, 1, &description, &audioConverter)
        
        if status != noErr{
            print("setup convert with error \(status)")
        }
    }
    
    
    func copyPCMSamplesIntoBuffer(_ ioData: UnsafeMutablePointer<AudioBufferList>) -> size_t{
        let originalBufferSize = pcmBufferSize
        if (originalBufferSize == 0){
            return originalBufferSize
        }
        ioData.pointee.mBuffers.mData = UnsafeMutableRawPointer.allocate(byteCount: pcmBufferSize, alignment: 0)
        ioData.pointee.mBuffers.mDataByteSize = UInt32(pcmBufferSize)
        pcmBuffer = nil
        pcmBufferSize = 0;
        
        return originalBufferSize
    }
    
    override func encode(_ sampleBuffer : CMSampleBuffer)
    {
        let timestamp:CMTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        encoderQueue.async {
            if (self.audioConverter == nil){
                self.setupEncoderFromSampleBuffer(sampleBuffer: sampleBuffer)
            }
            let blockBuffer: CMBlockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer)!
            
            var status : OSStatus = CMBlockBufferGetDataPointer(blockBuffer,
                                                                atOffset: 0,
                                                                lengthAtOffsetOut: nil,
                                                                totalLengthOut: &self.pcmBufferSize,
                                                                dataPointerOut: &self.pcmBuffer)
            
            var error : NSError?
            
            if(status != kCMBlockBufferNoErr){
                error = NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
            }
            
            memset(self.aacBuffer, 0, self.aacBufferSize)
            
            let outAudioBufferList : UnsafeMutableAudioBufferListPointer = AudioBufferList.allocate(maximumBuffers: 1)
            outAudioBufferList[0].mNumberChannels = 1;
            outAudioBufferList[0].mDataByteSize = UInt32(self.aacBufferSize)
            outAudioBufferList[0].mData = UnsafeMutableRawPointer.allocate(byteCount: self.aacBufferSize, alignment: 0)
            
            var ioOutputDataPacketSize: UInt32 = 1
            status = AudioConverterFillComplexBuffer(self.audioConverter!,
                                                     inInputDataProc,
                                                     Unmanaged.passUnretained(self).toOpaque(),
                                                     &ioOutputDataPacketSize,
                                                     outAudioBufferList.unsafeMutablePointer,
                                                     nil)
            
            var data: NSData?
            
            if(Int(status) == 0){
                let rawAAC : NSData  = NSData(bytes: outAudioBufferList[0].mData,
                                              length: Int(outAudioBufferList[0].mDataByteSize))
                
                let adtsHeader : NSData = self.adtsData(forPacketLength: rawAAC.length)! as NSData
                
                let fullData : NSMutableData = NSMutableData(data: adtsHeader as Data)
                
                fullData.append(rawAAC as Data)
                
                data = fullData
            }
            else{
                error = NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)
            }
            
            (self.delegate?.gotAudioEncodedData(data! as Data, timestamp: timestamp, error: error))!
            
        }
    }
    
    /**
     *  Add ADTS header at the beginning of each and every AAC packet.
     *  This is needed as MediaCodec encoder generates a packet of raw
     *  AAC data.
     *
     *  Note the packetLen must count in the ADTS header itself.
     *  See: http://wiki.multimedia.cx/index.php?title=ADTS
     *  Also: http://wiki.multimedia.cx/index.php?title=MPEG-4_Audio#Channel_Configurations
     **/
    func adtsData(forPacketLength packetLength: Int) -> Data? {
        let adtsLength = 7
        let packet : UnsafeMutablePointer<UInt8> = UnsafeMutablePointer.allocate(capacity: MemoryLayout<UInt8>.size * adtsLength)
        // Variables Recycled by addADTStoPacket
        let profile = 2 //AAC LC
        //39=MediaCodecInfo.CodecProfileLevel.AACObjectELD;
        let freqIdx = 4 //44.1KHz
        let chanCfg = 1 //MPEG-4 Audio Channel Configuration. 1 Channel front-center
        let fullLength = adtsLength + packetLength
        // fill in ADTS data
        packet[0] = UInt8(0xff) // 11111111      = syncword
        packet[1] = UInt8(0xf9) // 1111 1 00 1  = syncword MPEG-2 Layer CRC
        packet[2] = UInt8(((profile - 1) << 6)) + UInt8((freqIdx << 2) + (chanCfg >> 2))
        packet[3] = UInt8(((chanCfg & 3) << 6) + (fullLength >> 11))
        packet[4] = UInt8((fullLength & 0x7ff) >> 3)
        packet[5] = UInt8(((fullLength & 7) << 5) + 0x1f)
        packet[6] = UInt8(0xfc)
        let data = NSData(bytesNoCopy: packet, length: adtsLength, freeWhenDone: true)
        
        return data as Data
    }
}
