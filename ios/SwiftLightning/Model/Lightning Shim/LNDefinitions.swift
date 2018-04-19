//
//  LNDefinitions.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-17.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation

struct LNConstants {
  static let cipherSeedMnemonicWordCount = 24
  static let walletPasswordMinLength = 6
}


class GRPCResultError: NSError {
  static let domain = "GRPCResultDomain"
  
  override var localizedDescription: String {
    return userInfo["Message"] as! String
  }
  
  convenience init(code: Int, message: String) {
    self.init(domain: GRPCResultError.domain, code: code, userInfo: ["Message" : message])
  }
}


enum LNError: Int, Error {
  
  case createWalletInvalidCipherSeed
  case createWalletInvalidPassword
  
  case unlockWalletInvalidPassword
  
  
  // Computed Properties
  var code: Int { return self.rawValue }
  
  var localizedDescription: String {
    switch self {
      
    case .createWalletInvalidCipherSeed:
      return NSLocalizedString("Cipher seed invalid when creating wallet", comment: "LNError Type")
    case .createWalletInvalidPassword:
      return NSLocalizedString("Password invalid when creating wallet", comment: "LNError Type")
      
    case .unlockWalletInvalidPassword:
      return NSLocalizedString("Password invalid when unlocking wallet", comment: "LNError Type")
    }
  }
}
