//
//  LNManager.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-18.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation

class LNManager {
  
  struct Constants {
    static let defaultRetryCount: Int = 5
    static let defaultRetryDelay: Double = 1
  }
  
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
  
  static var isWalletPresent: Bool {
    guard let enumerator = FileManager.default.enumerator(atPath: LNServices.directoryPath) else {
      return false
    }
    
    let directoryURL = URL(fileURLWithPath: LNServices.directoryPath, isDirectory: true)
    
    for item in enumerator {
      let itemUrl = URL(fileURLWithPath: item as! String, relativeTo: directoryURL)
      
      if itemUrl.lastPathComponent == "wallet.db" {
        return true
      }
    }
    return false
  }
  
  static func validateNodePubKey(_ nodePubKey: String) -> Bool {
    // TODO: Actually validate the Node Pub Key
    return true
  }
  
  static func parsePortIPString(_ ipPortString: String) -> (ipString: String?, port: Int?) {
    var ipString: String?
    
    // Try to break into IP and Port
    let subStrings = ipPortString.split(separator: ":")
    guard subStrings.count == 2 else { return (nil, nil) }
    
    let ipAddressString = subStrings[0]
    let portString = subStrings[1]
    
    // Validate IP Address
    let ipOctetStrings = ipAddressString.split(separator: ".")
    
    if ipOctetStrings.count != 4 {
      ipString = nil
    } else {
      ipString = String(ipAddressString)
      for ipOctetString in ipOctetStrings {
        guard let ipOctet = Int(ipOctetString), ipOctet >= 0, ipOctet < 256 else {
          ipString = nil
          break
        }
      }
    }
    
    // Validate Port
    guard let port = Int(portString), port >= 0, port <= 99999 else {
      return (ipString, nil)
    }
    
    return (ipString, port)
  }
}
