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
    
    // Unary GRPC
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
    
    var request = Lnrpc_InitWalletRequest()
    request.cipherSeedMnemonic = cipherSeedMnemonic
    request.walletPassword = passwordData
    
    // Unary GRPC
    _ = try walletUnlockerService!.initWallet(request) { (response, result) in
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
    
    var request = Lnrpc_UnlockWalletRequest()
    request.walletPassword = passwordData
    
    // Unary GRPC
    _ = try walletUnlockerService!.unlockWallet(request) { (response, result) in
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
  
  
  // MARK: Wallet Balance
  
  static func walletBalance(retryCount: Int = LNManager.Constants.defaultRetryCount,
                            retryDelay: Double = LNManager.Constants.defaultRetryDelay,
                            completion: @escaping (() throws -> (total: Int, confirmed: Int, unconfirmed: Int)) -> Void) {
    let retry = SLRetry()
    let task = { () -> () in
      do {
        try prepareLightningService()
        
        // Unary GRPC
        _ = try lightningService!.walletBalance(Lnrpc_WalletBalanceRequest()) { (response, result) in
          if let response = response {
            let totalBalance = Int(response.totalBalance)
            let confirmedBalance = Int(response.confirmedBalance)
            let unconfirmedBalance = Int(response.unconfirmedBalance)
            
            // Success! - dereference retry
            retry.success()
            completion({ return (totalBalance, confirmedBalance, unconfirmedBalance) })
            
          } else {
            let message = result.statusMessage ?? result.description
            
            // Error - attempt to retry?
            retry.attempt(error: GRPCResultError(code: result.statusCode.rawValue, message: message))
          }
        }
      } catch {
        // Error - attempt to retry
        retry.attempt(error: error)
      }
    }
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Wallet Balance Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    retry.start("LN Wallet Balance", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: New Address
  
  static func newAddress(retryCount: Int = LNManager.Constants.defaultRetryCount,
                         retryDelay: Double = LNManager.Constants.defaultRetryDelay,
                        completion: @escaping (() throws -> (String)) -> Void) {
    
    let retry = SLRetry()
    let task = { () -> () in
      do {
        try prepareLightningService()
        
        var newAddressRequest = Lnrpc_NewAddressRequest()
        newAddressRequest.type = .nestedPubkeyHash
    
        // Unary GRPC
        _ = try lightningService!.newAddress(newAddressRequest) { (response, result) in
          
          if let response = response {
            SLLog.info("LN New Address Success!")
            
            // Success! - dereference retry
            retry.success()
            completion({ return response.address })
            
          } else {
            let message = result.statusMessage ?? result.description
            
            // Error - attempt to retry?
            retry.attempt(error: GRPCResultError(code: result.statusCode.rawValue, message: message))
          }
        }
      } catch {
        // Error - attempt to retry
        retry.attempt(error: error)
      }
    }
    let fail = { (error: Error) -> () in
      SLLog.warning("LN New Address Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    retry.start("LN New Address Failed", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: Connect Peer
  
  static func connectPeer(pubKey: String, hostAddr: String, hostPort: Int,
                          retryCount: Int = LNManager.Constants.defaultRetryCount,
                          retryDelay: Double = LNManager.Constants.defaultRetryDelay,
                          completion: @escaping (() throws -> ()) -> Void) {
    
    let retry = SLRetry()
    let task = { () -> () in
      do {
        try prepareLightningService()
        
        var addr = Lnrpc_LightningAddress()
        addr.pubkey = pubKey
        addr.host = "\(hostAddr):\(hostPort)"
        
        var request = Lnrpc_ConnectPeerRequest()
        request.addr = addr
        request.perm = true
        
        // Unary GRPC
        _ = try lightningService!.connectPeer(request) { (response, result) in
          if response != nil {
            SLLog.info("LN Connect Peer Success!")
            
            // Success! - dereference retry
            retry.success()
            completion({ return })
            
          } else {
            // Error - don't retry for this one
            let message = result.statusMessage ?? result.description
            completion({ throw GRPCResultError(code: result.statusCode.rawValue, message: message) })
          }
        }
        
      } catch {
        // Error - attempt to retry
        retry.attempt(error: error)
      }
    }
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Connect Peer Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    retry.start("LN Connect Peer", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: List Peers
  
  static func listPeers(retryCount: Int = LNManager.Constants.defaultRetryCount,
                        retryDelay: Double = LNManager.Constants.defaultRetryDelay,
                        completion: @escaping (() throws -> ()) -> Void) {
    let retry = SLRetry()
    let task = { () -> () in
      do {
        try prepareLightningService()
        
        // Unary GRPC
        _ = try lightningService!.listPeers(Lnrpc_ListPeersRequest()) { (response, result) in
          if let response = response {
            
            SLLog.verbose("LN List Peers Success!")
            
            for (index, peer) in response.peers.enumerated() {
              SLLog.verbose("")
              SLLog.verbose("Peer #\(index)")
              SLLog.verbose(" pub_key: \(peer.pubKey)")
              SLLog.verbose(" address: \(peer.address)")
              SLLog.verbose(" bytes_sent: \(peer.bytesSent)")
              SLLog.verbose(" bytes_recv: \(peer.bytesRecv)")
              SLLog.verbose(" sat_sent: \(peer.satSent)")
              SLLog.verbose(" sat_recv: \(peer.satRecv)")
              SLLog.verbose(" inbound: \(peer.inbound)")
              SLLog.verbose(" ping_time: \(peer.pingTime)")
            }
            
            // Success! - dereference retry
            retry.success()
            completion({ return })
            
          } else {
            let message = result.statusMessage ?? result.description
            
            // Error - attempt to retry?
            retry.attempt(error: GRPCResultError(code: result.statusCode.rawValue, message: message))
          }
        }
      } catch {
        // Error - attempt to retry
        retry.attempt(error: error)
      }
    }
    let fail = { (error: Error) -> () in
      SLLog.warning("LN List Peers Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    retry.start("LN List Peers", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: Get Info
  
  static func getInfo(retryCount: Int = LNManager.Constants.defaultRetryCount,
                      retryDelay: Double = LNManager.Constants.defaultRetryDelay,
                      completion: @escaping (() throws -> ()) -> Void) {  //TODO: Should return an info struct of sort
    
    let retry = SLRetry()
    let task = { () -> () in
      do {
        try prepareLightningService()
        
        // Unary GRPC
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
            
            // Success! - dereference retry
            retry.success()
            completion({ return })
            
          } else {
            let message = result.statusMessage ?? result.description
            
            // Error - attempt to retry?
            retry.attempt(error: GRPCResultError(code: result.statusCode.rawValue, message: message))
          }
        }
      } catch {
        // Error - attempt to retry
        retry.attempt(error: error)
      }
    }
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Get Info Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    retry.start("LN Get Info", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: List Channels
  
  static func listChannels(retryCount: Int = LNManager.Constants.defaultRetryCount,
                           retryDelay: Double = LNManager.Constants.defaultRetryDelay,
                           completion: @escaping (() throws -> ()) -> Void) {
    let retry = SLRetry()
    let task = { () -> () in
      do {
        try prepareLightningService()
        
        // Unary GRPC
        _ = try lightningService!.listChannels(Lnrpc_ListChannelsRequest()) { (response, result) in
          if let response = response {
            
            SLLog.verbose("LN List Channels Success!")
            
            for (index, channel) in response.channels.enumerated() {
              SLLog.verbose("")
              SLLog.verbose("Channel #\(index)")
              SLLog.verbose(" active: \(channel.active)")
              SLLog.verbose(" remote_pubkey: \(channel.remotePubkey)")
              SLLog.verbose(" channel_point: \(channel.channelPoint)")
              SLLog.verbose(" chan_id: \(channel.chanID)")
              SLLog.verbose(" capacity: \(channel.capacity)")
              SLLog.verbose(" local_balance: \(channel.localBalance)")
              SLLog.verbose(" remote_balance: \(channel.remoteBalance)")
              SLLog.verbose(" commit_fee: \(channel.commitFee)")
              SLLog.verbose(" commit_weight: \(channel.commitWeight)")
              SLLog.verbose(" fee_per_kw: \(channel.feePerKw)")
              SLLog.verbose(" unsettled_balance: \(channel.unsettledBalance)")
              SLLog.verbose(" total_satoshis_sent: \(channel.totalSatoshisSent)")
              SLLog.verbose(" total_satoshis_received: \(channel.totalSatoshisReceived)")
              SLLog.verbose(" num_updates: \(channel.numUpdates)")
              
              for (htlcIndex, htlc) in channel.pendingHtlcs.enumerated() {
                SLLog.verbose("")
                SLLog.verbose(" HTLC #\(htlcIndex)")
                SLLog.verbose("  incoming: \(htlc.incoming)")
                SLLog.verbose("  amount: \(htlc.amount)")
                SLLog.verbose("  hashLock: \(htlc.hashLock.hexEncodedString())")
                SLLog.verbose("  expirationHeight: \(htlc.expirationHeight)")
              }
              if channel.pendingHtlcs.count != 0 { SLLog.verbose("") }
              
              SLLog.verbose(" csv_delay: \(channel.csvDelay)")
              SLLog.verbose(" private: \(channel.private)")
            }
            
            // Success! - dereference retry
            retry.success()
            completion({ return })
            
          } else {
            let message = result.statusMessage ?? result.description
            
            // Error - attempt to retry?
            retry.attempt(error: GRPCResultError(code: result.statusCode.rawValue, message: message))
          }
        }
      } catch {
        // Error - attempt to retry
        retry.attempt(error: error)
      }
    }
    let fail = { (error: Error) -> () in
      SLLog.warning("LN List Channels Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    retry.start("LN List Channels", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: Open Channel
  
  static func openChannel(nodePubKey: Data, localFundingAmt: Int, pushSat: Int, targetConf: Int? = nil, satPerByte: Int? = nil,
                          retryCount: Int = LNManager.Constants.defaultRetryCount,
                          retryDelay: Double = LNManager.Constants.defaultRetryDelay,
                          streaming: @escaping (() throws -> (Lnrpc_LightningOpenChannelCall)) -> Void,
                          completion: @escaping (() throws -> ()) -> Void) {
    
    let retry = SLRetry()
    let task = { () -> () in
      do {
        try prepareLightningService()
        
        var request = Lnrpc_OpenChannelRequest()
        request.nodePubkey = nodePubKey
        request.localFundingAmount = Int64(localFundingAmt)
        request.pushSat = Int64(pushSat)

        if let targetConf = targetConf { request.targetConf = Int32(targetConf) }
        if let satPerByte = satPerByte { request.satPerByte = Int64(satPerByte) }
        
        // Server Streaming GRPC
        let call = try lightningService!.openChannel(request) { (result) in
          if result.success, result.statusCode.rawValue == 0 {
            SLLog.info("LN Open Channel Request Success!")
            completion({ return })
          }
          else {
            let message = result.statusMessage ?? result.description
            let error = GRPCResultError(code: result.statusCode.rawValue, message: message)
            SLLog.warning("LN Open Channel Resulted in Error - \(error.localizedDescription)")
            completion({ throw error })
          }
        }
        
        // Success! - dereference retry
        retry.success()
        streaming({ return call })

      } catch {
        // Error - attempt to retry
        retry.attempt(error: error)
      }
    }
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Open Channel Failed - \(error.localizedDescription)")
      streaming({ throw error })
    }
    
    retry.start("LN Open Channel", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: Stop Daemon
  
  static func stopDaemon(completion: @escaping (() throws -> ()) -> Void) throws {
    try prepareLightningService()
    
    // Unary GRPC
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
