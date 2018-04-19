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
  static private(set) var cipherSeedMnemonics: [String]?
 
  static func set(cipherSeedMnemonics: [String]) {
    guard cipherSeedMnemonics.count == LNConstants.cipherSeedMnemonicWordCount else {
      SLLog.fatal("CipherSeedMnemonics must be 24 words long!")
    }
    LNManager.cipherSeedMnemonics = cipherSeedMnemonics
  }
  
  static func getCipherSeedWord(index: Int) -> String? {
    return LNManager.cipherSeedMnemonics?[index]
  }
  
  static func clearCipherSeedMnemonics() {
    LNManager.cipherSeedMnemonics = nil
  }
}
