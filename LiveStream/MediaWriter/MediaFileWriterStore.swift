//
//  MediaFIleWriterManager.swift
//  RecordCamera
//
//  Created by CPU12015 on 10/2/19.
//  Copyright © 2019 CPU12015. All rights reserved.
//

import UIKit

enum MediaType : Int{
    case MP4
    case M4V
    case M4A
}
class MediaFIleWriterStore: NSObject {
    class func CreateMediaWriter(mediaType : MediaType) -> MediaFileWriter?{
        var mediaWriter : MediaFileWriter?
        
        switch mediaType {
        case .MP4:
            mediaWriter = MediaFileWriter(fileType: .MP4)
            if (mediaWriter?.createNewDefaultVideoInput())!, (mediaWriter?.createNewDefaultAudioInput())!{
                
            }
            
        case .M4V:
            mediaWriter = MediaFileWriter(fileType: .M4V)
            if (mediaWriter?.createNewDefaultVideoInput())!, (mediaWriter?.createNewDefaultAudioInput())!{
                
            }
            
        case .M4A:
            mediaWriter = MediaFileWriter(fileType: .M4A)
            if (mediaWriter?.createNewDefaultAudioInput())!{
                
            }
        }
        
        return mediaWriter
    }
}
