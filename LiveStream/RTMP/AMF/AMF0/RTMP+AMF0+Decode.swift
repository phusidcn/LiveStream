//
//  RTMP+AMF0+Decode.swift
//  LiveStream
//
//  Created by CPU11899 on 10/9/19.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import Foundation
let entryPoint = 0...3

enum AMF0DecodeError : Error {
    case rangeError
    case parseError
}

extension Data {
    public func decodeAMF0() -> [Any]? {
        var b = self
        return b.decode()
    }
}

extension Data {
    mutating func decode() -> [Any]? {
        var decodeData = [Any]()
        while let first = self.first {
            guard RTMPAMF0Type(rawValue: first) != nil else {
                return decodeData
            }
            self.remove(at: 0)
            do {
                try decode.append(self.parseValue(type : realType))
            } catch {
                print("Decode Error \(error.localizedDescription)")
                return nil
            }
        }
        return decodeData
    }
    
    mutating func parseValue(type: RTMPAMF0Type) throws -> Any {
        switch type {
        case .number:
            return try self.decodeNumber()
        case .boolean:
            return try self.decodeBool()
        case .string, .longString:
            return try self.decodeString(type: type)
        case .null:
            return nullString
        case .xml:
            return try self.decodeXML()
        case .date:
            return try self.decodeDate()
        case .object:
            return try self.decodeObj()
        case .typedObject:
            return try self.decodeTypeObject()
        case .array:
            return try self.decodeArray()
        case .strictArray:
            return try self.decodeStrictArray()
        case .switchAMF3:
            return "Unknown"
        default:
            return AMF0DecodeError.parseError
        }
    }
    
    mutating func decodeNumber() throws -> Double {
        let range = 0..<8
        guard let value = self[safe: range] else {
            throw AMF0DecodeError.rangeError
        }
        self.removeSubrange(range)
        let convert = Data(value.reversed()).double
        return convert
    }
    
    mutating func decodeBool() throws -> Bool {
        guard let result = self.first else {
            throw AMF0DecodeError.rangeError
        }
        self.remove(at: 0)
        return result == 0x01
    }
    
    mutating func decodeString(type : RTMPAMF0Type) throws -> String {
        let range = 0..<(type == .string ? 2 : 4)
        guard let rangeBytes = self[safe: range] else {
            throw AMF0DecodeError.rangeError
        }
        let length = Data(rangeBytes.reversed()).uint32
        self.removeSubrange(range)
        let value = self[0..<Int(length)].string
        self.removeSubrange(0..<Int(length)
        return value
    }
    
    mutating func decodeXML() throws -> String {
        let range = 0..<4
        guard let rangeBytes = self[safe: range] else {
            throw AMF0DecodeError.rangeError
        }
        let length = Data(rangeBytes.reversed()).uint32
        self.removeSubrange(range)
        let value = self[0..<Int(length)].string
        self.removeSubrange(0..<Int(length))
        return value
    }
    
    mutating func decodeDate() throws -> Date {
        guard let value = self[safe: 0..<8] else {
            throw AMF0DecodeError.rangeError
        }
        let convert = Data(value.reversed()).double
        let result = Date(timeIntervalSince1970: convert/1000)
        self.removeSubrange(0..<10)
        return result
    }
}

