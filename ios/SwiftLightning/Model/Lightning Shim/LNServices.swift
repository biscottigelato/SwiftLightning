//
//  LND.swift
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
    
    #if DEBUG
    lndArgs += "--debuglevel=debug"
    #else
    lndArgs += "--debuglevel=info"
    #endif

    SCLog.verbose("LND Arguments: \(lndArgs)")
    
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
  
  private static func prepareWalletUnlockerService() {
    if walletUnlockerService == nil {
      let tlsCertURL = URL(fileURLWithPath: LNServices.directoryPath).appendingPathComponent("tls.cert")
      let tlsCert = try! String(contentsOf: tlsCertURL)
      
      walletUnlockerService = Lnrpc_WalletUnlockerServiceClient(address: "localhost:\(LNServices.rpcListenPort)", certificates: tlsCert, host: nil)
    }
  }
  
  
  // MARK: Generate Seed
  
  static func generateSeed(completion: @escaping ([String]?, LNError?) -> ()) -> LNError? {
    prepareWalletUnlockerService()
    
    do {
      _ = try walletUnlockerService!.genSeed(Lnrpc_GenSeedRequest()) { (response, result) in
        if let response = response {
          SCLog.info("LN Generate Seed Success!")
          
          #if DEBUG  // CAUTION: Make double sure this only gets logged on Debug
          var ciperSeedMnemonicDisplayString = "Generated Mnemonic: "
          for mnemonicWord in response.cipherSeedMnemonic {
            ciperSeedMnemonicDisplayString += mnemonicWord
            ciperSeedMnemonicDisplayString += " "
          }
          SCLog.verbose(ciperSeedMnemonicDisplayString)
          #endif
          
          completion(response.cipherSeedMnemonic, nil)
          
        } else {
          SCLog.warning("LN Generate Seed Failed - \(result)")
          completion(nil, LNError.GenerateSeedFailedAsync(result.description))
        }
      }
    } catch {
      return LNError.GenerateSeedErrorSync(error.localizedDescription)
    }
    
    return nil
  }
  
  
  // MARK: Create Wallet
  
  static func createWallet(walletPassword: String,
                    cipherSeedMnemonic: [String],
                    completion: @escaping (LNError?) -> ()) -> LNError? {
    
    guard cipherSeedMnemonic.count == LNConstants.cipherSeedMnemonicWordCount else {
      SCLog.warning("Cipher Seed Mnemonic is not 24 words long!")
      return LNError.CreateWalletInvalidCipherSeedSync
    }
    
    guard walletPassword.count < LNConstants.walletPasswordMinLength, let passwordData = walletPassword.data(using: .utf8) else {
      SCLog.warning("Invalid Wallet Password")
      return LNError.CreateWalletInvalidPasswordSync
    }
    
    prepareWalletUnlockerService()
    
    var initWalletRequest = Lnrpc_InitWalletRequest()
    initWalletRequest.cipherSeedMnemonic = cipherSeedMnemonic
    initWalletRequest.walletPassword = passwordData
    
    do {
      _ = try walletUnlockerService!.initWallet(initWalletRequest) { (response, result) in
        if response != nil {
          SCLog.info("LN Create Wallet Success!")
          completion(nil)
        } else {
          SCLog.warning("LN Create Wallet Failed - \(result)")
          completion(LNError.CreateWalletFailedAsync(result.description))
        }
      }
    } catch {
      return LNError.CreateWalletErrorSync(error.localizedDescription)
    }
    
    return nil
  }
  
  
  // MARK: Unlock Wallet
  
  static func unlockWallet(walletPassword: String, completion: @escaping (LNError?) -> ()) -> LNError? {
    
    guard let passwordData = walletPassword.data(using: .utf8) else {
      SCLog.warning("Invalid Wallet Password")
      return LNError.UnlockWalletInvalidPasswordSync
    }
    
    prepareWalletUnlockerService()
    
    var unlockWalletRequest = Lnrpc_UnlockWalletRequest()
    unlockWalletRequest.walletPassword = passwordData
    
    do {
      _ = try walletUnlockerService!.unlockWallet(unlockWalletRequest) { (response, result) in
        if response != nil {
          SCLog.info("LN Unlock Wallet Success!")
          completion(nil)
        } else {
          SCLog.warning("LN Unlock Wallet Failed - \(result)")
          completion(LNError.UnlockWalletFailedSAsync(result.description))
        }
      }
    } catch {
      return LNError.UnlockWalletErrorSync(error.localizedDescription)
    }
    
    return nil
  }
  
  
  // MARK: Lightning Service
  
  static var lightningService: Lnrpc_LightningServiceClient?
  
  static private func prepareLightningService() {
    if lightningService == nil {
      let tlsCertURL = URL(fileURLWithPath: LNServices.directoryPath).appendingPathComponent("tls.cert")
      let tlsCert = try! String(contentsOf: tlsCertURL)  // TODO: Error Handling
      
      let macaroonURL = URL(fileURLWithPath: LNServices.directoryPath).appendingPathComponent("admin.macaroon")
      let macaroonBinary = try! Data(contentsOf: macaroonURL)  // TODO: Error Handling
      let macaroonHexString = macaroonBinary.hexEncodedString()
      
      lightningService = Lnrpc_LightningServiceClient(address: "localhost:\(LNServices.rpcListenPort)", certificates: tlsCert, host: nil)
      lightningService!.metadata.add(key: "macaroon", value: macaroonHexString)
    }
  }
  
  
  // MARK: Get Info
  
  static func getInfo(completion: @escaping (LNError?) -> ()) -> LNError? {  //TODO: Should return an info struct of sort
    prepareLightningService()
    
    do {
      _ = try lightningService!.getInfo(Lnrpc_GetInfoRequest()) { (response, result) in
        if let response = response {
          SCLog.verbose("LN Get Info Success!")
          SCLog.verbose("Identity Pubkey:       \(response.identityPubkey)")
          SCLog.verbose("Alias:                 \(response.alias)")
          SCLog.verbose("Num Pending Channels:  \(response.numPendingChannels)")
          SCLog.verbose("Num Active Channels :  \(response.numActiveChannels)")
          SCLog.verbose("Number of Peers:       \(response.numPeers)")
          SCLog.verbose("Block Height:          \(response.blockHeight)")
          SCLog.verbose("Block Hash:            \(response.blockHash)")
          SCLog.verbose("Synced to Chain:       \(response.syncedToChain)")
          SCLog.verbose("Testnet:               \(response.testnet)")
          SCLog.verbose("Chains:                \(response.chains.joined(separator: ", "))")
          SCLog.verbose("URIs:                  \(response.uris.joined(separator: ", "))")
          SCLog.verbose("Best Header Timestamp: \(response.bestHeaderTimestamp)")
          
          completion(nil)
        } else {
          SCLog.warning("LN Get Info Failed - \(result)")
          completion(LNError.GetInfoFailedAsync(result.description))
        }
      }
    } catch {
      return LNError.GetInfoErrorSync(error.localizedDescription)
    }
    
    return nil
  }
}
