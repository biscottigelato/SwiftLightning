//
//  LNServices.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-06.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation
import Lightningd

class LNServices {
  
  // MARK: Initialization
  
  static var rpcListenPort: UInt = 10009
  static var peerListenPort: UInt = 9735
  static var restListenPort: UInt = 8080
  static var neutrinoAddress: String = "btcd0.lightning.computer:18333"
  static var directoryPath: String = ""
  static var lndQueue: DispatchQueue?
  
  static func initialize() {
    
    getenv("HOME")
    
    // Obtain the path to Application Support
    guard let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.path else {
      fatalError("Cannot get Application Support Folder URL")
    }
    directoryPath = appSupportPath + "/lnd"
    
    // Arguments for LND Start
    var lndArgs = ""
    lndArgs += "--bitcoin.active"
    lndArgs += " "
    lndArgs += "--bitcoin.testnet"
    lndArgs += " "
    lndArgs += "--bitcoin.node=neutrino"
    lndArgs += " "
    lndArgs += "--neutrino.connect=\(neutrinoAddress)"
    lndArgs += " "
    lndArgs += "--rpclisten=localhost:\(rpcListenPort)"
    lndArgs += " "
    lndArgs += "--listen=localhost:\(peerListenPort)"
    lndArgs += " "
    lndArgs += "--restlisten=localhost:\(restListenPort)"
    lndArgs += " "
//    lndArgs += "--autopilot.active=1"
//    lngArgs += " "
//    lndArgs += "--no-macaroons"
//    lndArgs += " "
    
//    #if DEBUG
//    lndArgs += "--debuglevel=debug"
//    #else
    lndArgs += "--debuglevel=info"
//    #endif

    SLLog.verbose("LND Arguments: \(lndArgs)")
    
    // BTCD can throw SIGPIPEs. Ignoring according to https://developer.apple.com/library/content/documentation/NetworkingInternetWeb/Conceptual/NetworkingOverview/CommonPitfalls/CommonPitfalls.html for now
    signal(SIGPIPE, SIG_IGN)
    
    // Start LND on it's own thread
    lndQueue = DispatchQueue(label: "LNDQueue", qos: .background, attributes: .concurrent)
    
    lndQueue!.async {
      LightningdStartLND(appSupportPath, lndArgs)
    }
    
    // For some reason GRPC Core have a very limited Cipher Suite set for SSL connections. This sets the environmental variable so
    // GRPC Core will expand the Cipher Suite set
    setenv("GRPC_SSL_CIPHER_SUITES", "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384", 1)
  }
  
  
  // MARK: Wallet Unlocker Service
  
  static var walletUnlockerService: Lnrpc_WalletUnlockerServiceClient?
  
  private static func prepareWalletUnlockerService() throws {
    if walletUnlockerService == nil {
      let tlsCertURL = URL(fileURLWithPath: LNServices.directoryPath).appendingPathComponent("tls.cert")
      let tlsCert = try String(contentsOf: tlsCertURL)
      
      walletUnlockerService = Lnrpc_WalletUnlockerServiceClient(address: "localhost:\(LNServices.rpcListenPort)", certificates: tlsCert, host: nil)
    }
  }

  
  // MARK: Generate Seed
  
  static func generateSeed(completion: @escaping (() throws -> ([String])) -> Void) throws {
    try prepareWalletUnlockerService()
    
    _ = try walletUnlockerService!.genSeed(Lnrpc_GenSeedRequest()) { (response, result) in
      if let response = response {
        SLLog.info("LN Generate Seed Success!")
        
        #if DEBUG  // CAUTION: Make double sure this only gets logged on Debug
        var ciperSeedMnemonicDisplayString = "Generated Mnemonic: "
        for mnemonicWord in response.cipherSeedMnemonic {
          ciperSeedMnemonicDisplayString += mnemonicWord
          ciperSeedMnemonicDisplayString += " "
        }
        SLLog.verbose(ciperSeedMnemonicDisplayString)
        #endif
        
        completion({ return response.cipherSeedMnemonic })
        
      } else {
        let message = result.statusMessage ?? result.description
        SLLog.warning("LN Generate Seed Failed - \(message)")
        completion({ throw GRPCResultError(code: result.statusCode.rawValue, message: message) })
      }
    }
  }
  
  
  // MARK: Create Wallet
  
  static func createWallet(walletPassword: String,
                           cipherSeedMnemonic: [String],
                           completion: @escaping (() throws -> ()) -> Void) throws {
    
    guard cipherSeedMnemonic.count == LNConstants.cipherSeedMnemonicWordCount else {
      SLLog.warning("Cipher Seed Mnemonic is not 24 words long!")
      throw LNError.createWalletInvalidCipherSeed
    }
    
    guard walletPassword.count > LNConstants.walletPasswordMinLength, let passwordData = walletPassword.data(using: .utf8) else {
      SLLog.warning("Invalid Wallet Password")
      throw LNError.createWalletInvalidPassword
    }
    
    try prepareWalletUnlockerService()
    
    var initWalletRequest = Lnrpc_InitWalletRequest()
    initWalletRequest.cipherSeedMnemonic = cipherSeedMnemonic
    initWalletRequest.walletPassword = passwordData
    
    _ = try walletUnlockerService!.initWallet(initWalletRequest) { (response, result) in
      if response != nil {
        SLLog.info("LN Create Wallet Success!")
        completion({ return })
      } else {
        let message = result.statusMessage ?? result.description
        SLLog.warning("LN Create Wallet Failed - \(message)")
        completion({ throw GRPCResultError(code: result.statusCode.rawValue, message: message) })
      }
    }
  }
  
  
  // MARK: Unlock Wallet
  
  static func unlockWallet(walletPassword: String,
                           completion: @escaping (() throws -> ()) -> Void) throws {
    
    guard let passwordData = walletPassword.data(using: .utf8) else {
      SLLog.warning("Invalid Wallet Password")
      throw LNError.unlockWalletInvalidPassword
    }
    
    try prepareWalletUnlockerService()
    
    var unlockWalletRequest = Lnrpc_UnlockWalletRequest()
    unlockWalletRequest.walletPassword = passwordData
    
    _ = try walletUnlockerService!.unlockWallet(unlockWalletRequest) { (response, result) in
      if response != nil {
        SLLog.info("LN Unlock Wallet Success!")
        completion({ return })
      } else {
        let message = result.statusMessage ?? result.description
        SLLog.warning("LN Unlock Wallet Failed - \(message)")
        completion({ throw GRPCResultError(code: result.statusCode.rawValue, message: message) })
      }
    }
  }
  
  
  // MARK: Lightning Service
  
  static var lightningService: Lnrpc_LightningServiceClient?
  
  static private func prepareLightningService() throws {
    if lightningService == nil {
      let tlsCertURL = URL(fileURLWithPath: LNServices.directoryPath).appendingPathComponent("tls.cert")
      let tlsCert = try String(contentsOf: tlsCertURL)  // TODO: Error Handling
      
      let macaroonURL = URL(fileURLWithPath: LNServices.directoryPath).appendingPathComponent("admin.macaroon")
      let macaroonBinary = try Data(contentsOf: macaroonURL)  // TODO: Error Handling
      let macaroonHexString = macaroonBinary.hexEncodedString()
      
      lightningService = Lnrpc_LightningServiceClient(address: "localhost:\(LNServices.rpcListenPort)", certificates: tlsCert, host: nil)
      lightningService!.metadata.add(key: "macaroon", value: macaroonHexString)
    }
  }
  
  
  // MARK: New Address
  
  static func newAddress(completion: @escaping (() throws -> (String)) -> Void) throws {
    try prepareLightningService()
    
    var newAddressRequest = Lnrpc_NewAddressRequest()
    newAddressRequest.type = .nestedPubkeyHash
    
    _ = try lightningService!.newAddress(newAddressRequest) { (response, result) in
      if let response = response {
        SLLog.info("LN New Wallet Success!")
        
        completion({ return response.address })
        
      } else {
        let message = result.statusMessage ?? result.description
        SLLog.warning("LN New Address Failed - \(message)")
        completion({ throw GRPCResultError(code: result.statusCode.rawValue, message: message) })
      }
    }
  }
  
  
  // MARK: Get Info
  
  static func getInfo(completion: @escaping (() throws -> ()) -> Void) throws {  //TODO: Should return an info struct of sort
    try prepareLightningService()
    
    _ = try lightningService!.getInfo(Lnrpc_GetInfoRequest()) { (response, result) in
      if let response = response {
        SLLog.verbose("LN Get Info Success!")
        SLLog.verbose("Identity Pubkey:       \(response.identityPubkey)")
        SLLog.verbose("Alias:                 \(response.alias)")
        SLLog.verbose("Num Pending Channels:  \(response.numPendingChannels)")
        SLLog.verbose("Num Active Channels :  \(response.numActiveChannels)")
        SLLog.verbose("Number of Peers:       \(response.numPeers)")
        SLLog.verbose("Block Height:          \(response.blockHeight)")
        SLLog.verbose("Block Hash:            \(response.blockHash)")
        SLLog.verbose("Synced to Chain:       \(response.syncedToChain)")
        SLLog.verbose("Testnet:               \(response.testnet)")
        SLLog.verbose("Chains:                \(response.chains.joined(separator: ", "))")
        SLLog.verbose("URIs:                  \(response.uris.joined(separator: ", "))")
        SLLog.verbose("Best Header Timestamp: \(response.bestHeaderTimestamp)")
        
        completion({ return })
      } else {
        let message = result.statusMessage ?? result.description
        SLLog.warning("LN Get Info Failed - \(message)")
        completion({ throw GRPCResultError(code: result.statusCode.rawValue, message: message) })
      }
    }
  }
  
  
  // MARK: Stop Daemon
  
  static func stopDaemon(completion: @escaping (() throws -> ()) -> Void) throws {
    try prepareLightningService()
    
    _ = try lightningService!.stopDaemon(Lnrpc_StopRequest()) { (response, result) in
      if response != nil {
        SLLog.info("Stop Daemon Success!")
        completion({ return })
      } else {
        let message = result.statusMessage ?? result.description
        SLLog.warning("Stop Daemon Failed - \(message)")
        completion({ throw GRPCResultError(code: result.statusCode.rawValue, message: message) })
      }
    }
  }
  
}
