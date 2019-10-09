//
//  RTMP+AMF3Protocol.swift
//  LiveStream
//
//  Created by Huynh Lam Phu Si on 10/9/19.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import Foundation
enum AMF3EncodeType {
    enum U29 : UInt8 {
        case value = 0x01
        case reference = 0x00
        
        init?(rawValue: UInt8) {
            switch rawValue {
            case 0x00:
                self = .reference
            case 0x01:
                self = .value
            default:
                return nil
            }
        }
    }
    
    enum Vector : UInt8 {
        case fix = 0x01
        case dynamic = 0x00
    }
}

protocol AMF3LengthEncode {
    var amf3LengthConvert: Data { get }
}

protocol AMF3Encode {
    var amf3Encode : Data { get }
}

protocol AMF3KeyEncode {
    var amf3KeyEncode: Data { get }
}

protocol AMF3ByteArrayEncode {
    var byteEncode : Data { get }
}

protocol AMF3VectorEncode {
    var amf3VectorEncode: Data { get }
}

protocol AMF3VectorUnitEncode {
    var vectorData: Data { get }
}
