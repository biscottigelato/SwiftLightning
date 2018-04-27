//
//  Data+Extension.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-06.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation

extension Data {
  struct HexEncodingOptions: OptionSet {
    let rawValue: Int
    static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    static let littleEndian = HexEncodingOptions(rawValue: 1 << 1)  // Byte 0 at the right most in String
  }
  
  func hexEncodedString(options: HexEncodingOptions = []) -> String {
    let hexDigits = Array((options.contains(.upperCase) ? "0123456789ABCDEF" : "0123456789abcdef").utf16)
    var chars: [unichar] = []
    chars.reserveCapacity(2 * count)
    for byte in self {
      if options.contains(.littleEndian) {
        chars.insert(hexDigits[Int(byte % 16)], at: 0)
        chars.insert(hexDigits[Int(byte / 16)], at: 0)
      } else {
        chars.append(hexDigits[Int(byte / 16)])
        chars.append(hexDigits[Int(byte % 16)])
      }
    }
    return String(utf16CodeUnits: chars, count: chars.count)
  }
  
  init?(hexString: String) {
    let length = hexString.count
    guard length & 1 == 0 else { return nil }  // Must be even characters
    
    var bytes = [UInt8]()
    bytes.reserveCapacity(length/2)
    
    var index = hexString.startIndex
    for _ in 0..<length/2 {
      let nextIndex = hexString.index(index, offsetBy: 2)
      guard let byte = UInt8(hexString[index..<nextIndex], radix: 16) else { return nil }
      bytes.append(byte)
      index = nextIndex
    }
    
    self.init(bytes: bytes)
  }
}
