//
//  LNManager.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-18.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation

class LNManager {
  
  // Temporary storage. Shall be cleared when done setting up wallet
  static private(set) var cipherSeedMnemonic: [String]?
 
  static func set(cipherSeedMnemonic: [String]) {
    guard cipherSeedMnemonic.count == LNConstants.cipherSeedMnemonicWordCount else {
      SLLog.fatal("CipherSeedMnemonic must be 24 words long!")
    }
    LNManager.cipherSeedMnemonic = cipherSeedMnemonic
  }
  
  static func getCipherSeedWord(index: Int) -> String? {
    return LNManager.cipherSeedMnemonic?[index]
  }
  
  static func clearCipherSeedMnemonic() {
    LNManager.cipherSeedMnemonic = nil
  }
}
