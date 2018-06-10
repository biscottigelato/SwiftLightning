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
    case lightning = "lightning:"
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
    case lightning = "lightning:"
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
    if inputString.hasPrefix(PayReqPrefixes.lnbtc.rawValue) || inputString.hasPrefix(PayReqPrefixes.lightning.rawValue) {
      paymentType = BitcoinPaymentType.lightning
      
      address = inputString
      if inputString.hasPrefix(PayReqPrefixes.lightning.rawValue) {
        address = String(inputString.dropFirst(PayReqPrefixes.lightning.rawValue.count))
      }
      
      // LND barfs if there are differing cases
      address = address!.lowercased()
      
      LNServices.decodePayReq(address!) { (responder) in
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
  
  
  // MARK: BootstrapPeers Connect
  
  static func connectBootstrapPeers() {
    LNServices.listPeers { (peersResponse) in
      do {
        let connectedPeers = try peersResponse()
        let peerNodePubKeys = connectedPeers.map({ $0.pubKey })
        
        for bootstrapPeer in BootstrapPeer.list {
          if !peerNodePubKeys.contains(bootstrapPeer.nodePubKey) {
            LNServices.connectPeer(pubKey: bootstrapPeer.nodePubKey,
                                   hostAddr: bootstrapPeer.nodeAddr,
                                   hostPort: bootstrapPeer.port) { response in
              do {
                _ = try response()
                SLLog.info("Bootstrapped with LN node \(bootstrapPeer.nodePubKey):\(bootstrapPeer.nodeAddr)@\(bootstrapPeer.port)")
              } catch {
                SLLog.warning("Bootstrap failed with LN node \(bootstrapPeer.nodePubKey):\(bootstrapPeer.nodeAddr)@\(bootstrapPeer.port)")
              }
            }
          }
        }
      } catch {
        SLLog.warning("List Peers for Bootstrap Failed!")
      }
    }
  }
  
  
  // MARK: Reconnect Disconnected Channels

  static func reconnectAllChannels() {
    SLLog.debug("Attempt to reconnect all channels")
    
    LNServices.listChannels { (listResponder) in
      do {
        let channels = try listResponder()
        let dChannels = channels.filter({ !$0.isActive })  // Get only channels that are inactive
        let dPubKeys = dChannels.map({ $0.remotePubKey })  // Extract pubkeys for these channels
        let uniquePubKeys = Array(Set(dPubKeys))  // Remove duplicates so we only connect to a node once
        
        for pubKey in uniquePubKeys {
          LNServices.getNodeInfo(pubKey: pubKey) { (nodeResponder) in
            do {
              let nodeInfo = try nodeResponder()
              
              if nodeInfo.address.count > 0 {
                let ipPort = nodeInfo.address[0].split(separator: ":")
                let ipAddr = String(ipPort[0])
                
                if let port = Int(ipPort[1]) {
                  // Best effort connect
                  LNServices.connectPeer(pubKey: nodeInfo.pubKey, hostAddr: ipAddr, hostPort: port) { _ in }
                }
              }
            } catch {
              SLLog.warning("Cannot get node info for \(pubKey) - \(error.localizedDescription)")
            }
          }
        }
    
      } catch {
        SLLog.warning("Cannot list channels - \(error.localizedDescription)")
      }
    }
  }
  
  
  // MARK: Change lnd.conf debug level
  
  static func changeDebugLevel(withLevelSpec levelSpecString: String) throws {
    let lndConfURL = URL(fileURLWithPath: LNServices.directoryPath).appendingPathComponent("lnd.conf", isDirectory: false)
    let tempLndConfURL = URL(fileURLWithPath: LNServices.directoryPath).appendingPathComponent("lnd.temp", isDirectory: false)
    
    do {
      let lndConfText = try String(contentsOf: lndConfURL, encoding: .utf8)
      var newLndConfText: String = ""
      
      // Find a line that contains 'debuglevel'
      lndConfText.enumerateLines { (line, stop) in
        var newLine = line
        if line.range(of:"debuglevel") != nil {
          newLine = "debuglevel=\(levelSpecString)"
        }
        newLndConfText += newLine
        newLndConfText += "\n"
      }
      
      // Create a new file, and then replace the original lnd.conf
      try newLndConfText.write(to: tempLndConfURL, atomically: true, encoding: .utf8)
      _ = try FileManager.default.replaceItemAt(lndConfURL, withItemAt: tempLndConfURL, backupItemName: "lnd.bak")
      
    } catch {
      throw LNError.lndConfLNDCofRWError(error.localizedDescription)
    }
  }
  
  
  // MARK: Read/Change lnd.conf Neutrino Peers
  
  static func findNeutrinoPeers(andReplaceWith newPeers: [String]? = nil) throws -> [String] {
    let lndConfURL = URL(fileURLWithPath: LNServices.directoryPath).appendingPathComponent("lnd.conf", isDirectory: false)
    let tempLndConfURL = URL(fileURLWithPath: LNServices.directoryPath).appendingPathComponent("lnd.temp", isDirectory: false)
    
    do {
      let lndConfText = try String(contentsOf: lndConfURL, encoding: .utf8)
      var newLndConfText: String = ""
      var peerAddrs = [String]()
      
      // Find a line that contains 'neutrino.addpeer'
      lndConfText.enumerateLines { (line, stop) in
        var newLine = line
        
        // If it's found, find the address and throw the line away
        if let range = newLine.range(of:"neutrino.addpeer=") {
          newLine.removeSubrange(newLine.startIndex..<range.upperBound)
          peerAddrs.append(newLine.trimmingCharacters(in: .whitespacesAndNewlines))
          
        // If not found, just add back to the new LND conf file
        } else {
          newLndConfText += newLine
          newLndConfText += "\n"
        }
      }
      
      // Add the new Peer Addresses
      if let newPeers = newPeers {
        for newPeer in newPeers {
          newLndConfText += "neutrino.addpeer=\(newPeer)"
          newLndConfText += "\n"
        }
      
        // Create a new file, and then replace the original lnd.conf
        try newLndConfText.write(to: tempLndConfURL, atomically: true, encoding: .utf8)
        _ = try FileManager.default.replaceItemAt(lndConfURL, withItemAt: tempLndConfURL, backupItemName: "lnd.bak")
      }
      
      return peerAddrs
      
    } catch {
      throw LNError.lndConfLNDCofRWError(error.localizedDescription)
    }
  }
  
  
  // MARK: lnd.conf version
  
  static func getLndConfVersion(for url: URL) -> Int? {
    do {
      let lndConfText = try String(contentsOf: url, encoding: .utf8)
      var lndConfStrings = [String]()
      var swiftLightningLineNum: Int?
      
      // Find a line that contains 'SwiftLightning'
      lndConfText.enumerateLines { (line, stop) in
        lndConfStrings.append(line)
        if line.range(of:"[SwiftLightning]") != nil {
          swiftLightningLineNum = lndConfStrings.count - 1
        }
      }
      
      if let index = swiftLightningLineNum {
        
        // Extract version on the next line
        var versionLine = lndConfStrings[index+1]
        if let range = versionLine.range(of:"version=") {
          versionLine.removeSubrange(versionLine.startIndex..<range.upperBound)
          return Int(versionLine.trimmingCharacters(in: .whitespacesAndNewlines))
        }
      }
      return nil
      
    } catch {
      SLLog.warning("Cannot read lnd.conf at \(url.absoluteString) - \(error.localizedDescription)")
      return nil
    }
  }
  
  
  // MARK: Read LND Log
  
  static func getLndLogURL() -> URL {
    return URL(fileURLWithPath: LNServices.directoryPath).appendingPathComponent("/logs/bitcoin/testnet/lnd.log", isDirectory: false)
  }
}
