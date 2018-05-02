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
  
  
  // MARK: Node Pub Key handling
  
  
  static func splitKeyAddressString(_ inputString: String) -> (key: String, addr: String?) {
    let subStrings = inputString.split(separator: "@", maxSplits: 2)
    
    if subStrings.count == 2 {
      return (String(subStrings[0]), String(subStrings[1]))
    } else {
      return (String(subStrings[0]), nil)
    }
  }
  
  
  static func validateNodePubKey(_ nodePubKey: String) -> Bool {
    // Just to make sure the string is valid hex
    guard let nodePubKeyData = Data(hexString: nodePubKey) else {
      return false
    }
    
    // Must be 33 bytes in length for compressed bitcoin public key
    guard nodePubKeyData.count == 33 else {
      return false
    }

    // Must start with 02 or 03 as according to SECP256K1
    guard nodePubKey.hasPrefix("02") || nodePubKey.hasPrefix("03") else {
      return false
    }
    
    return true
  }
  
  
  // MARK: Port IP Handling
  
  
  static func parsePortIPString(_ ipPortString: String) -> (ipString: String?, port: Int?) {
    var ipString: String?
    var port: Int? = LNConstants.defaultLightningNodePort
    
    // Try to break into IP and Port
    let subStrings = ipPortString.split(separator: ":")
    guard subStrings.count > 0, subStrings.count < 3 else { return (nil, nil) }
    
    // TODO: Actually Validate the address. But given it can also be a named domain.. It's difficult...
    ipString = String(subStrings[0])
    
    if subStrings.count == 2 {
      // Validate Port
      if let validPort = Int(subStrings[1]), validPort >= LNConstants.minValidLightningPort, validPort <= LNConstants.maxValidLightningPort {
        port = validPort
      } else {
        port = nil
      }
    }

    return (ipString, port)
  }
  
  
  // MARK: Payment Address Handling
  
  // if Mainnet
  // typealias AddressPrefixes = MainnetAddressPrefixes
  // typealias PayReqPrefixes = MainnetPayreqPrefixes
  
  private enum MainnetPayReqPrefixes: String {
    case btcuri = "bitcoin:"
    case lnbtc  = "lnbc"
  }
  
  private enum MainnetAddressPrefixes: String {
    case p2pkh  = "1"
    case p2sh   = "3"
    case bech32 = "bc1"
  }
  
  // if Testnet
  private typealias AddressPrefixes = TestnetAddressPrefixes
  private typealias PayReqPrefixes = TestnetPayreqPrefixes
  
  private enum TestnetPayreqPrefixes: String {
    case btcuri = "bitcoin:"
    case lnbtc  = "lntb"
  }
  
  private enum TestnetAddressPrefixes: String {
    case p2pkh1 = "m"
    case p2pkh2 = "n"
    case p2sh   = "2"
    case bech32 = "tb1"
  }
  
  static func determineAddress(inputString: String,
                               completion: @escaping (String?, Bitcoin?, String?, BitcoinPaymentType?, Bool?) -> ()) {
    
    var address: String?
    var amount: Bitcoin?
    var description: String?
    var paymentType: BitcoinPaymentType?
    
    // Deal with Payment Requests first

    // Lightning Invoice? Processing ends inside if so
    if inputString.hasPrefix(PayReqPrefixes.lnbtc.rawValue) {
      paymentType = BitcoinPaymentType.lightning
      
      LNServices.decodePayReq(inputString) { (responder) in
        do {
          let lnPayReq = try responder()
          address = lnPayReq.destination
          amount = Bitcoin(inSatoshi: lnPayReq.numSatoshis)
          description = lnPayReq.payDescription
          completion(address, amount, description, paymentType, true)
          
        } catch {
          // Can't even decode...
          completion(nil, nil, nil, paymentType, nil)
        }
      }
      return  // Go no further. Processing is Async from this point on for LN.
    }
    
    // Bitcoin Payment Request?
    else if inputString.hasPrefix(PayReqPrefixes.btcuri.rawValue) {
      paymentType = BitcoinPaymentType.onChain
        
      // Looks like one. Attempt to decode
      do {
        let payReq = try PaymentURI(inputString)
        address = payReq.address
        description = payReq.label
        
        if let payReqAmt = payReq.amount {
          amount = Bitcoin(payReqAmt)
        }
        
      } catch {
        // Doesn't look like a valid payment request
        completion(nil, nil, nil, paymentType, false)
        return
      }
    }

    // So we should have something that kinda resembles a Bitcoin address at this point. Validate
    if address == nil { address = inputString }
    paymentType = BitcoinPaymentType.onChain
    
    // TODO: The following statement needs to be modified to be Mainnet compatible
    if address!.hasPrefix(AddressPrefixes.p2pkh1.rawValue) || address!.hasPrefix(AddressPrefixes.p2pkh2.rawValue) || address!.hasPrefix(AddressPrefixes.p2sh.rawValue) {
      do {
        _ = try Address(address!)
        completion(address, amount, description, paymentType, true)
        
      } catch {
        completion(address, amount, description, paymentType, false)
      }
    }
    
    // SegWit Address type
    else if address!.hasPrefix(AddressPrefixes.bech32.rawValue) {
      do {
        _ = try SegwitAddrCoder.shared.decode(addr: address!)
        completion(address, amount, description, paymentType, true)
      } catch {
        completion(address, amount, description, paymentType, false)
      }
    }
    
    // So nothing hit for the address. If this is from a Payment Request, some of the following stuff might be != nil
    else {
      completion(address, amount, description, paymentType, false)
    }
  }
}
