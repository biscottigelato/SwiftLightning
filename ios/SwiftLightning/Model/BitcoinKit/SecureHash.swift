//
//  SecureHash.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-29.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation

struct SecureHash {
  
  static func sha256(_ data: Data) -> Data {
    let nsData = data as NSData
    
    var hash = Array<UInt8>(repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
    CC_SHA256(nsData.bytes, CC_LONG(nsData.length), &hash)
    
    return NSData(bytes: &hash, length: Int(CC_SHA256_DIGEST_LENGTH)) as Data
  }
  
  static func sha256sha256(_ data: Data) -> Data {
    return sha256(sha256(data))
  }
}
