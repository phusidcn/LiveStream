//
//  RTMP+CVImageBuffer+Convert.swift
//  LiveStream
//
//  Created by Huynh Lam Phu Si on 10/10/19.
//  Copyright © 2019 ThangNVH. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
extension CVImageBuffer {
    func convert() -> UIImage {
        return UIImage(ciImage: CIImage(cvImageBuffer: self))
    }
}
