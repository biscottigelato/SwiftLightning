//
//  LNServices.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-06.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation
import Lndmobile


class LNDMobileStartCallback: NSObject, LndmobileCallbackProtocol {
  func onError(_ p0: Error!) {
    SLLog.verbose("LND Calledback with Error \(p0.localizedDescription)")
  }
  
  func onResponse(_ p0: Data!) {
    SLLog.verbose("LND Calledback with Data")
  }
}


class LNServices {
  
  // MARK: Initialization
  
  static var rpcListenPort: UInt = 10009
  static var peerListenPort: UInt = 9735
  static var restListenPort: UInt = 8080
  static var neutrinoAddress: String = "faucet.lightning.community"
  static var directoryPath: String = ""
  static var lndQueue: DispatchQueue?
  
  static func initialize() {
    
    getenv("HOME")
    
    // Obtain the path to Application Support
    guard let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.path else {
      SLLog.fatal("Cannot get Application Support Folder URL")
    }
    directoryPath = appSupportPath + "/lnd"
    
    // Copy lnd.conf to the LND directoryPath
    guard let lndSourceURL = Bundle.main.url(forResource: "lnd", withExtension: "conf") else {
      SLLog.fatal("Cannot get in Bundle lnd.conf")
    }
    let lndDestinationURL = URL(fileURLWithPath: directoryPath).appendingPathComponent("lnd.conf", isDirectory: false)
    
    do {
      try FileManager.default.copyItem(at: lndSourceURL, to: lndDestinationURL)
    } catch CocoaError.fileWriteFileExists {
      SLLog.debug("lnd.conf already exist at Applicaiton Support/lnd")
    } catch {
      let nsError = error as NSError
      SLLog.fatal("Failed to copy lnd.conf from bundle to Application Support/lnd - \(nsError.domain): \(nsError.code)")
    }
    
    // BTCD can throw SIGPIPEs. Ignoring according to https://developer.apple.com/library/content/documentation/NetworkingInternetWeb/Conceptual/NetworkingOverview/CommonPitfalls/CommonPitfalls.html for now
    signal(SIGPIPE, SIG_IGN)
    
    // Start LND on it's own thread
    lndQueue = DispatchQueue(label: "LNDQueue", qos: .background, attributes: .concurrent)
    
    lndQueue!.async {
      LndmobileStart(directoryPath, LNDMobileStartCallback())
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
        SLLog.debug("LN Generate Seed Success!")
        
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
        SLLog.debug("LN Create Wallet Success!")
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
        SLLog.debug("LN Unlock Wallet Success!")
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
  
  class WalletBalance: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> (total: Int, confirmed: Int, unconfirmed: Int)) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> (total: Int, confirmed: Int, unconfirmed: Int)) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        let response = try Lnrpc_WalletBalanceResponse(serializedData: p0)
        SLLog.debug("LN Wallet Balance Success!")
        
        let totalBalance = Int(response.totalBalance)
        let confirmedBalance = Int(response.confirmedBalance)
        let unconfirmedBalance = Int(response.unconfirmedBalance)
        
        SLLog.verbose("Total Balance: \(response.totalBalance)")
        SLLog.verbose("Confirmed Balance: \(response.confirmedBalance)")
        SLLog.verbose("Unconfirmed Balance: \(response.unconfirmedBalance)")
        
        // Success! - dereference retry
        retry.success()
        completion({ return (totalBalance, confirmedBalance, unconfirmedBalance) })
      } catch {
        completion({ throw error })
      }
    }
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  
  static func walletBalance(retryCount: Int = LNConstants.defaultRetryCount,
                            retryDelay: Double = LNConstants.defaultRetryDelay,
                            completion: @escaping (() throws -> (total: Int, confirmed: Int, unconfirmed: Int)) -> Void) {
    
    let lndOp = WalletBalance(completion)
    
    let task = {
      do {
        let request = try Lnrpc_WalletBalanceRequest().serializedData()
        LndmobileWalletBalance(request, lndOp)
      } catch {
        completion({ throw error })
      }
    }
    
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Wallet Balance Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    lndOp.retry.start("LN Wallet Balance", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: Channel Balance
  
  class ChannelBalance: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> (Int)) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> (Int)) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        let response = try Lnrpc_ChannelBalanceResponse(serializedData: p0)
        SLLog.debug("LN Channel Balance Success!")
        SLLog.verbose("Channel Balance: \(response.balance)")
        
        // Success! - dereference retry
        retry.success()
        completion({ return Int(response.balance) })
      } catch {
        completion({ throw error })
      }
    }
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  static func channelBalance(retryCount: Int = LNConstants.defaultRetryCount,
                            retryDelay: Double = LNConstants.defaultRetryDelay,
                            completion: @escaping (() throws -> (Int)) -> Void) {
    let lndOp = ChannelBalance(completion)
    
    let task = {
      do {
        let request = try Lnrpc_WalletBalanceRequest().serializedData()
        LndmobileChannelBalance(request, lndOp)
      } catch {
        completion({ throw error })
      }
    }
    
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Channel Balance Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    lndOp.retry.start("LN Channel Balance", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: Get Transactions
  
  static func getTransactions(retryCount: Int = LNConstants.defaultRetryCount,
                             retryDelay: Double = LNConstants.defaultRetryDelay,
                             completion: @escaping (() throws -> ([BTCTransaction])) -> Void) {
    let retry = SLRetry()
    let task = { () -> () in
      do {
        try prepareLightningService()
        
        // Unary GRPC
        _ = try lightningService!.getTransactions(Lnrpc_GetTransactionsRequest()) { (response, result) in
          if let response = response {
            SLLog.debug("Get Bitcoin Transactions Success!")
            var btcTransactions = [BTCTransaction]()
            
            for (index, transaction) in response.transactions.enumerated() {
              let btcTransaction = BTCTransaction(txHash: transaction.txHash,
                                                  amount: Int(transaction.amount),
                                                  numConfirmations: Int(transaction.numConfirmations),
                                                  blockHash: transaction.blockHash,
                                                  blockHeight: Int(transaction.blockHeight),
                                                  timeStamp: Int(transaction.timeStamp),
                                                  totalFees: Int(transaction.totalFees),
                                                  destAddresses: transaction.destAddresses)
              
              btcTransactions.append(btcTransaction)
              
              SLLog.verbose("")
              SLLog.verbose("Bitcoin Transaction #\(index)")
              SLLog.verbose(String(describing: btcTransaction))
            }
            
            // Success! - dereference retry
            retry.success()
            completion({ return btcTransactions })
            
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
      SLLog.warning("Get Bitcoin Transactions Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    retry.start("Get Bitcoin Transactions", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: Send Coins
  
  static func sendCoins(address: String, amount: Int, targetConf: Int? = nil, satPerByte: Int? = nil,
                        retryCount: Int = LNConstants.defaultRetryCount,
                        retryDelay: Double = LNConstants.defaultRetryDelay,
                        completion: @escaping (() throws -> (String)) -> Void) {
    
    let retry = SLRetry()
    let task = { () -> () in
      do {
        try prepareLightningService()
    
        var request = Lnrpc_SendCoinsRequest()
        request.addr = address
        request.amount = Int64(amount)
        
        if let targetConf = targetConf { request.targetConf = Int32(targetConf) }
        if let satPerByte = satPerByte { request.satPerByte = Int64(satPerByte) }
        
        // Unary GRPC
        _ = try lightningService!.sendCoins(request) { (response, result) in

          if let response = response {
            SLLog.debug("LN Send Coins Success!")
            
            // Success. Deference retry
            retry.success()
            completion({ response.txid })
            
          } else {
            let message = result.statusMessage ?? result.description
            retry.attempt(error: GRPCResultError(code: result.statusCode.rawValue, message: message))
          }
        }
      } catch {
        // Error - attempt to retry
        retry.attempt(error: error)
      }
    }
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Send Coins Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    retry.start("LN Send Coins", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: New Address
  
  static func newAddress(retryCount: Int = LNConstants.defaultRetryCount,
                         retryDelay: Double = LNConstants.defaultRetryDelay,
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
            SLLog.debug("LN New Address Success!")
            
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
                          retryCount: Int = LNConstants.defaultRetryCount,
                          retryDelay: Double = LNConstants.defaultRetryDelay,
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
          
          // We won't retry anymore after getting here. Deference retry
          retry.success()
          
          if response != nil {
            SLLog.debug("LN Connect Peer Success!")
            completion({ return })
          } else {
            let message = result.statusMessage ?? result.description
            if message.contains("already connected") {  // TODO: Hack: Is there a better way?
              SLLog.warning(message)
              completion({ return })
            } else {
              completion({ throw GRPCResultError(code: result.statusCode.rawValue, message: message) })
            }
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
  
  static func listPeers(retryCount: Int = LNConstants.defaultRetryCount,
                        retryDelay: Double = LNConstants.defaultRetryDelay,
                        completion: @escaping (() throws -> ([LNPeer])) -> Void) {
    let retry = SLRetry()
    let task = { () -> () in
      do {
        try prepareLightningService()
        
        // Unary GRPC
        _ = try lightningService!.listPeers(Lnrpc_ListPeersRequest()) { (response, result) in
          if let response = response {
            SLLog.debug("LN List Peers Success!")
            
            var lnPeers = [LNPeer]()
            for (index, peer) in response.peers.enumerated() {
              
              let lnPeer = LNPeer(pubKey: peer.pubKey,
                                  address: peer.address,
                                  bytesSent: UInt(peer.bytesSent),
                                  bytesRecv: UInt(peer.bytesRecv),
                                  satSent: Int(peer.satSent),
                                  satRecv: Int(peer.satRecv),
                                  inbound: peer.inbound,
                                  pingTime: Int(peer.pingTime))
              
              lnPeers.append(lnPeer)
              
              SLLog.verbose("")
              SLLog.verbose("Peer #\(index)")
              SLLog.verbose(String(describing: lnPeer))
            }
            
            // Success! - dereference retry
            retry.success()
            completion({ return lnPeers })
            
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
  
  class GetInfo: NSObject, LndmobileCallbackProtocol {
    
    private var completion: (() throws -> (LNDInfo)) -> Void
    let retry = SLRetry()
    
    init(_ completion: @escaping (() throws -> (LNDInfo)) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        let response = try Lnrpc_GetInfoResponse(serializedData: p0)
        SLLog.debug("LN Get Info Success!")
        
        let lndInfo = LNDInfo(identityPubkey: response.identityPubkey,
                              alias: response.alias,
                              numPendingChannels: UInt(response.numPendingChannels),
                              numActiveChannels: UInt(response.numActiveChannels),
                              numPeers: UInt(response.numPeers),
                              blockHeight: response.blockHeight,
                              blockHash: response.blockHash,
                              syncedToChain: response.syncedToChain,
                              testnet: response.testnet,
                              chains: response.chains,
                              uris: response.uris,
                              bestHeaderTimestamp: Int(response.bestHeaderTimestamp))
        
        SLLog.verbose(String(describing: lndInfo))
        
        // Success! - dereference retry
        retry.success()
        completion({ return lndInfo })
      } catch {
        completion({ throw error })
      }
    }
    
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  static func getInfo(retryCount: Int = LNConstants.defaultRetryCount,
                      retryDelay: Double = LNConstants.defaultRetryDelay,
                      completion: @escaping (() throws -> (LNDInfo)) -> Void) {
    
    let lndOp = GetInfo(completion)
    
    let task = {
      do {
        let request = try Lnrpc_GetInfoRequest().serializedData()
        LndmobileGetInfo(request, lndOp)
      } catch {
        completion({ throw error })
      }
    }
    
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Get Info Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    lndOp.retry.start("LN Get Info", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: Pending Channels
  
  static func pendingChannels(retryCount: Int = LNConstants.defaultRetryCount,
                              retryDelay: Double = LNConstants.defaultRetryDelay,
                              completion: @escaping (() throws -> (pendingOpen: [LNPendingOpenChannel],
                                                                   pendingClose: [LNPendingCloseChannel],
                                                                   pendingForceClose: [LNPendingForceCloseChannel])) -> Void) {
    let retry = SLRetry()
    let task = { () -> () in
      do {
        try prepareLightningService()
        
        // Unary GRPC
        _ = try lightningService!.pendingChannels(Lnrpc_PendingChannelsRequest()) { (response, result) in
          if let response = response {
            SLLog.debug("LN Pending Channels Success!")
            
            var lnPendingOpenChannels = [LNPendingOpenChannel]()
            for (index, pendingOpenChannel) in response.pendingOpenChannels.enumerated() {
              
              let lnPendingChannel = LNPendingChannel(remoteNodePub: pendingOpenChannel.channel.remoteNodePub,
                                                      channelPoint: pendingOpenChannel.channel.channelPoint,
                                                      capacity: Int(pendingOpenChannel.channel.capacity),
                                                      localBalance: Int(pendingOpenChannel.channel.localBalance),
                                                      remoteBalance: Int(pendingOpenChannel.channel.remoteBalance))
              
              let lnPendingOpenChannel = LNPendingOpenChannel(channel: lnPendingChannel,
                                                              confirmationHeight: UInt(pendingOpenChannel.confirmationHeight),
                                                              commitFee: Int(pendingOpenChannel.commitFee),
                                                              commitWeight: Int(pendingOpenChannel.commitWeight),
                                                              feePerKw: Int(pendingOpenChannel.feePerKw))
              
              lnPendingOpenChannels.append(lnPendingOpenChannel)
              
              SLLog.verbose("")
              SLLog.verbose("Pending Open Channel #\(index)")
              SLLog.verbose(String(describing: lnPendingOpenChannel))
            }
              
            var lnPendingCloseChannels = [LNPendingCloseChannel]()
            for (index, pendingCloseChannel) in response.pendingClosingChannels.enumerated() {
              
              let lnPendingChannel = LNPendingChannel(remoteNodePub: pendingCloseChannel.channel.remoteNodePub,
                                                      channelPoint: pendingCloseChannel.channel.channelPoint,
                                                      capacity: Int(pendingCloseChannel.channel.capacity),
                                                      localBalance: Int(pendingCloseChannel.channel.localBalance),
                                                      remoteBalance: Int(pendingCloseChannel.channel.remoteBalance))
              
              let lnPendingCloseChannel = LNPendingCloseChannel(channel: lnPendingChannel, closingTxID: pendingCloseChannel.closingTxid)
              lnPendingCloseChannels.append(lnPendingCloseChannel)
              
              SLLog.verbose("")
              SLLog.verbose("Pending Close Channel #\(index)")
              SLLog.verbose(String(describing: lnPendingCloseChannel))
            }
            
            var lnPendingForceCloseChannels = [LNPendingForceCloseChannel]()
            for (index, pendingForceCloseChannel) in response.pendingForceClosingChannels.enumerated() {
              
              let lnPendingChannel = LNPendingChannel(remoteNodePub: pendingForceCloseChannel.channel.remoteNodePub,
                                                      channelPoint: pendingForceCloseChannel.channel.channelPoint,
                                                      capacity: Int(pendingForceCloseChannel.channel.capacity),
                                                      localBalance: Int(pendingForceCloseChannel.channel.localBalance),
                                                      remoteBalance: Int(pendingForceCloseChannel.channel.remoteBalance))
              
              var lnPendingHTLCs = [LNPendingHTLC]()
              for pendingHTLC in pendingForceCloseChannel.pendingHtlcs {
                let lnPendingHTLC = LNPendingHTLC(incoming: pendingHTLC.incoming,
                                                  amount: Int(pendingHTLC.amount),
                                                  outpoint: pendingHTLC.outpoint,
                                                  maturityHeight: UInt(pendingHTLC.maturityHeight),
                                                  blocksTilMaturity: Int(pendingHTLC.blocksTilMaturity),
                                                  stage: UInt(pendingHTLC.stage))
                lnPendingHTLCs.append(lnPendingHTLC)
              }
              
              let lnPendingForceCloseChannel = LNPendingForceCloseChannel(channel: lnPendingChannel,
                                                                          closingTxID: pendingForceCloseChannel.closingTxid,
                                                                          limboBalance: Int(pendingForceCloseChannel.limboBalance),
                                                                          maturityHeight: UInt(pendingForceCloseChannel.maturityHeight),
                                                                          blocksTilMaturity: Int(pendingForceCloseChannel.blocksTilMaturity),
                                                                          recoveredBalance: Int(pendingForceCloseChannel.recoveredBalance),
                                                                          pendingHTLCs: lnPendingHTLCs)
              lnPendingForceCloseChannels.append(lnPendingForceCloseChannel)
              
              SLLog.verbose("")
              SLLog.verbose("Pending Force Close Channel #\(index)")
              SLLog.verbose(String(describing: lnPendingForceCloseChannel))
            }
            
            // Success! - dereference retry
            retry.success()
            completion({ return (lnPendingOpenChannels, lnPendingCloseChannels, lnPendingForceCloseChannels) })
            
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
      SLLog.warning("LN Pending Channels Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    retry.start("LN Pending Channels", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: List Channels
  
  static func listChannels(retryCount: Int = LNConstants.defaultRetryCount,
                           retryDelay: Double = LNConstants.defaultRetryDelay,
                           completion: @escaping (() throws -> ([LNChannel])) -> Void) {
    let retry = SLRetry()
    let task = { () -> () in
      do {
        try prepareLightningService()
        
        // Unary GRPC
        _ = try lightningService!.listChannels(Lnrpc_ListChannelsRequest()) { (response, result) in
          if let response = response {
            SLLog.debug("LN List Channels Success!")
            
            var lnChannels = [LNChannel]()
            for (index, channel) in response.channels.enumerated() {
              
              var lnHTLCs = [LNHTLC]()
              for htlc in channel.pendingHtlcs {
                let lnHTLC = LNHTLC(incoming: htlc.incoming,
                                    amount: Int(htlc.amount),
                                    hashLock: htlc.hashLock,
                                    expirationHeight: UInt(htlc.expirationHeight))
                lnHTLCs.append(lnHTLC)
              }
              
              let lnChannel = LNChannel(isActive: channel.active,
                                        remotePubKey: channel.remotePubkey,
                                        channelPoint: channel.channelPoint,
                                        chanID: UInt(channel.chanID),
                                        capacity: Int(channel.capacity),
                                        localBalance: Int(channel.localBalance),
                                        remoteBalance: Int(channel.remoteBalance),
                                        commitFee: Int(channel.commitFee),
                                        commitWeight: Int(channel.commitWeight),
                                        feePerKw: Int(channel.feePerKw),
                                        unsettledBalance: Int(channel.unsettledBalance),
                                        totalSatoshisSent: Int(channel.totalSatoshisSent),
                                        totalSatoshisReceived: Int(channel.totalSatoshisReceived),
                                        numUpdates: UInt(channel.numUpdates),
                                        pendingHTLCs: lnHTLCs,
                                        csvDelay: UInt(channel.csvDelay),
                                        isPrivate: channel.private)
              lnChannels.append(lnChannel)
              
              SLLog.verbose("")
              SLLog.verbose("Channel #\(index)")
              SLLog.verbose(String(describing: lnChannel))
            }
            
            // Success! - dereference retry
            retry.success()
            completion({ return lnChannels })
            
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
  
  class OpenChannel: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> ()) -> Void
    let retry = SLRetry()
    
    init(_ completion: @escaping (() throws -> ()) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) { completion({ return }) }
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  static func openChannel(nodePubKey: Data, localFundingAmt: Int, pushSat: Int, targetConf: Int? = nil, satPerByte: Int? = nil,
                          retryCount: Int = LNConstants.defaultRetryCount,
                          retryDelay: Double = LNConstants.defaultRetryDelay,
                          streaming: @escaping (() throws -> (Lnrpc_LightningOpenChannelCall)) -> Void,
                          completion: @escaping (() throws -> ()) -> Void) {
    
    let lnOp = OpenChannel(completion)
    
    let task = { () -> () in
      
      var request = Lnrpc_OpenChannelRequest()
      request.nodePubkey = nodePubKey
      request.localFundingAmount = Int64(localFundingAmt)
      request.pushSat = Int64(pushSat)

      if let targetConf = targetConf { request.targetConf = Int32(targetConf) }
      if let satPerByte = satPerByte { request.satPerByte = Int64(satPerByte) }
    
      do {
        let serializedReq = try request.serializedData()
        
        // TODO: How do one get a stream back through direct binding????
        LndmobileOpenChannel(serializedReq, lnOp)
        
      } catch {
        completion({ throw error })
        return
      }
    
      // Dereference retry
      lnOp.retry.success()
        
//        do {
//          try call.receive { (result) in
//            switch result {
//            case .result(let resultType):
//              guard let update = resultType?.update else {
//                SLLog.warning("LN Open Channel call stream result with no type")
//                streaming({ throw LNError.openChannelStreamNoType })
//                break
//              }
//
//              switch update {
//              case .chanPending(let pendingUpdate):
//                SLLog.verbose("LN Open Channel Pending Update:")
//                SLLog.verbose(" TXID:          \(pendingUpdate.txid.hexEncodedString(options: .littleEndian))")
//                SLLog.verbose(" Output Index:  \(pendingUpdate.outputIndex)")
//
//              case .confirmation(let confirmUpdate):
//                SLLog.verbose("LN Open Channel Confirmation Update:")
//                SLLog.verbose(" Block SHA:          \(confirmUpdate.blockSha.hexEncodedString(options: .littleEndian))")
//                SLLog.verbose(" Block Height:       \(confirmUpdate.blockHeight)")
//                SLLog.verbose(" Num of Confs Left:  \(confirmUpdate.numConfsLeft)")
//
//              case .chanOpen(let openUpdate):
//                SLLog.verbose("LN Open Channel Open Update:")
//                SLLog.verbose(" TXID:          \(openUpdate.channelPoint.fundingTxidStr)")
//                SLLog.verbose(" Output Index:  \(openUpdate.channelPoint.outputIndex)")
//              }
//              streaming({ return call })
//
//            case .error(let error):
//              SLLog.warning("LN Open Channel call stream error - \(error.localizedDescription)")
//              streaming({ throw error })
//            }
//          }
//        } catch {
//          SLLog.warning("LNOpen Channel call stream thrown - \(error.localizedDescription)")
//          streaming({ throw error })
//        }
    }
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Open Channel Failed - \(error.localizedDescription)")
      streaming({ throw error })
    }
    
    lnOp.retry.start("LN Open Channel", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }

  
  // MARK: Open Channel
  
  static func closeChannel(fundingTxIDStr: String, outputIndex: UInt, force: Bool,
                           targetConf: Int? = nil, satPerByte: Int? = nil,
                           retryCount: Int = LNConstants.defaultRetryCount,
                           retryDelay: Double = LNConstants.defaultRetryDelay,
                           streaming: @escaping (() throws -> (Lnrpc_LightningCloseChannelCall)) -> Void,
                           completion: @escaping (() throws -> ()) -> Void) {
    
    let retry = SLRetry()
    let task = { () -> () in
      do {
        try prepareLightningService()
        
        var channelPoint = Lnrpc_ChannelPoint()
        channelPoint.fundingTxidStr = fundingTxIDStr
        channelPoint.outputIndex = UInt32(outputIndex)
        
        var request = Lnrpc_CloseChannelRequest()
        request.channelPoint = channelPoint
        request.force = force
        
        if let targetConf = targetConf { request.targetConf = Int32(targetConf) }
        if let satPerByte = satPerByte { request.satPerByte = Int64(satPerByte) }
        
        // Server Streaming GRPC
        let call = try lightningService!.closeChannel(request) { (result) in
          if result.success, result.statusCode.rawValue == 0 {
            SLLog.debug("LN Close Channel Resulted in Success!")
            completion({ return })
          }
          else {
            let message = result.statusMessage ?? result.description
            let error = GRPCResultError(code: result.statusCode.rawValue, message: message)
            SLLog.warning("LN Close Channel Resulted in Error - \(error.localizedDescription)")
            completion({ throw error })
          }
        }
        
        // Dereference retry
        retry.success()
        
        do {
          try call.receive { (result) in
            switch result {
            case .result(let resultType):
              guard let update = resultType?.update else {
                SLLog.warning("LN Close Channel call stream result with no type")
                streaming({ throw LNError.closeChannelStreamNoType })
                break
              }
              
              switch update {
              case .closePending(let pendingUpdate):
                SLLog.verbose("LN Close Channel Pending Update:")
                SLLog.verbose(" TXID:          \(pendingUpdate.txid.hexEncodedString(options: .littleEndian))")
                SLLog.verbose(" Output Index:  \(pendingUpdate.outputIndex)")
                
              case .confirmation(let confirmUpdate):
                SLLog.verbose("LN Close Channel Confirmation Update:")
                SLLog.verbose(" Block SHA:          \(confirmUpdate.blockSha.hexEncodedString(options: .littleEndian))")
                SLLog.verbose(" Block Height:       \(confirmUpdate.blockHeight)")
                SLLog.verbose(" Num of Confs Left:  \(confirmUpdate.numConfsLeft)")
                
              case .chanClose(let closeUpdate):
                SLLog.verbose("LN Close Channel Update:")
                SLLog.verbose(" Closing TxID:  \(closeUpdate.closingTxid.hexEncodedString())")
                SLLog.verbose(" Success:       \(closeUpdate.success)")
              }
              streaming({ return call })
              
            case .error(let error):
              SLLog.warning("LN Close Channel call stream error - \(error.localizedDescription)")
              streaming({ throw error })
            }
          }
        } catch {
          SLLog.warning("LN Close Channel call stream thrown - \(error.localizedDescription)")
          streaming({ throw error })
        }
      } catch {
        // Error - attempt to retry
        retry.attempt(error: error)
      }
    }
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Close Channel Failed - \(error.localizedDescription)")
      streaming({ throw error })
    }
    
    retry.start("LN Close Channel", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: Send Payment Sync
  
  static func sendPaymentSync(dest: Data? = nil, amount: Int? = nil, payHash: Data? = nil, payReq: String? = nil, finalCLTVDelta: Int? = nil,
                              retryCount: Int = LNConstants.defaultRetryCount,
                              retryDelay: Double = LNConstants.defaultRetryDelay,
                              completion: @escaping (() throws -> (payError: String, payPreImage: Data, payRoute: LNRoute)) -> Void) {
    
    let retry = SLRetry()
    let task = { () -> () in
      do {
        try prepareLightningService()

        var request = Lnrpc_SendRequest()
        if let dest = dest { request.dest = dest }
        if let amount = amount { request.amt = Int64(amount) }
        if let payHash = payHash { request.paymentHash = payHash }
        if let payReq = payReq { request.paymentRequest = payReq }
        if let finalCTLVDelta = finalCLTVDelta { request.finalCltvDelta = Int32(finalCTLVDelta) }
        
        // Unary GRPC
        _ = try lightningService!.sendPaymentSync(request) { (response, result) in

          if let response = response {
            SLLog.debug("LN Send Payment Sync Success!")
            
            var lnHops = [LNHop]()
            
            for hop in response.paymentRoute.hops {
              let lnHop = LNHop(chanID: UInt(hop.chanID),
                                chanCapacity: Int(hop.chanCapacity),
                                amtToForward: Int(hop.amtToForward),
                                fee: Int(hop.fee),
                                expiry: UInt(hop.expiry))
              lnHops.append(lnHop)
            }
            
            let lnRoute = LNRoute(totalTimeLock: UInt(response.paymentRoute.totalTimeLock),
                                  totalFees: Int(response.paymentRoute.totalFees),
                                  totalAmt: Int(response.paymentRoute.totalAmt),
                                  hops: lnHops)
            
            // Success. Deference retry
            retry.success()
            completion({ return (response.paymentError, response.paymentPreimage, lnRoute) })
            
          } else {
            let message = result.statusMessage ?? result.description
            retry.attempt(error: GRPCResultError(code: result.statusCode.rawValue, message: message))
          }
        }
      } catch {
        // Error - attempt to retry
        retry.attempt(error: error)
      }
    }
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Send Payment Sync Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    retry.start("LN Send Payment Sync", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: Get Node Info
  
  static func getNodeInfo(pubKey: String,
                          retryCount: Int = LNConstants.defaultRetryCount,
                          retryDelay: Double = LNConstants.defaultRetryDelay,
                          completion: @escaping (() throws -> (LNNode)) -> Void) {
    let retry = SLRetry()
    let task = { () -> () in
      do {
        try prepareLightningService()
        
        var request = Lnrpc_NodeInfoRequest()
        request.pubKey = pubKey
        
        // Unary GRPC
        _ = try lightningService!.getNodeInfo(request) { (nodeInfo, result) in
          if let nodeInfo = nodeInfo {
            SLLog.debug("LN Get Node Info Success!")
    
            let lnNode = LNNode(lastUpdate: UInt(nodeInfo.node.lastUpdate),
                                pubKey: nodeInfo.node.pubKey,
                                alias: nodeInfo.node.alias,
                                network: nodeInfo.node.addresses.map { $0.network },
                                address: nodeInfo.node.addresses.map { $0.addr },
                                color: nodeInfo.node.color,
                                numChannels: UInt(nodeInfo.numChannels),
                                totalCapacity: Int(nodeInfo.totalCapacity))
            
            SLLog.verbose(String(describing: lnNode))
            
            // Success! - dereference retry
            retry.success()
            completion({ return lnNode })
            
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
      SLLog.warning("LN Get Node Info Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    retry.start("LN Get Node Info", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: QueryRoutes
  
  static func queryRoutes(pubKey: String, amt: Int, numRoutes: Int,
                          retryCount: Int = LNConstants.defaultRetryCount,
                          retryDelay: Double = LNConstants.defaultRetryDelay,
                          completion: @escaping (() throws -> ([LNRoute])) -> Void) {
    
    let retry = SLRetry()
    let task = { () -> () in
      do {
        try prepareLightningService()
        
        var request = Lnrpc_QueryRoutesRequest()
        request.pubKey = pubKey
        request.amt = Int64(amt)
        request.numRoutes = Int32(numRoutes)
        
        _ = try lightningService!.queryRoutes(request) { (response, result) in
          
          if let response = response {
            SLLog.debug("LN Query Routes Success!")
            
            var lnRoutes = [LNRoute]()
            for route in response.routes {
              
              var lnHops = [LNHop]()
              for hop in route.hops {
                lnHops.append(LNHop(chanID: UInt(hop.chanID),
                                    chanCapacity: Int(hop.chanCapacity),
                                    amtToForward: Int(hop.amtToForward),
                                    fee: Int(hop.fee),
                                    expiry: UInt(hop.expiry)))
              }
              
              lnRoutes.append(LNRoute(totalTimeLock: UInt(route.totalTimeLock),
                                      totalFees: Int(route.totalFees),
                                      totalAmt: Int(route.totalAmt),
                                      hops: lnHops))
            }
            
            SLLog.verbose("")
            SLLog.verbose(String(describing: lnRoutes))
            
            // Success! - dereference retry
            retry.success()
            completion({ return lnRoutes })
            
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
      SLLog.warning("LN Query Routes Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    retry.start("LN Query Routes", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: DecodePayReq
  
  static func decodePayReq(_ payReqInput: String,
                           retryCount: Int = LNConstants.defaultRetryCount,
                           retryDelay: Double = LNConstants.defaultRetryDelay,
                           completion: @escaping (() throws -> (LNPayReq)) -> Void) {
    let retry = SLRetry()
    let task = { () -> () in
      do {
        try prepareLightningService()
        
        var payReqString = Lnrpc_PayReqString()
        payReqString.payReq = payReqInput
        
        // Unary GRPC
        _ = try lightningService!.decodePayReq(payReqString) { (payReq, result) in
          
          if let payReq = payReq {
            SLLog.debug("LN Decode Pay Req Success!")
            
            let lnPayReq = LNPayReq(destination: payReq.destination,
                                    paymentHash: payReq.paymentHash,
                                    numSatoshis: Int(payReq.numSatoshis),
                                    timestamp: Int(payReq.timestamp),
                                    expiry: Int(payReq.expiry),
                                    payDescription: payReq.description_p,
                                    descriptionHash: payReq.paymentHash,
                                    fallbackAddr: payReq.fallbackAddr,
                                    cltvExpiry: Int(payReq.cltvExpiry))
          
            SLLog.verbose("")
            SLLog.verbose(String(describing: lnPayReq))
            
            // Success! - dereference retry
            retry.success()
            completion({ return lnPayReq })
            
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
      SLLog.warning("LN Decode Pay Req Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    retry.start("LN Decode Pay Req", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: List Payments
  
  static func listPayments(retryCount: Int = LNConstants.defaultRetryCount,
                           retryDelay: Double = LNConstants.defaultRetryDelay,
                           completion: @escaping (() throws -> ([LNPayment])) -> Void) {
    let retry = SLRetry()
    let task = { () -> () in
      do {
        try prepareLightningService()
        
        // Unary GRPC
        _ = try lightningService!.listPayments(Lnrpc_ListPaymentsRequest()) { (response, result) in
          if let response = response {
            SLLog.debug("List LN Payments Success!")
            var lnPayments = [LNPayment]()
            
            for (index, payment) in response.payments.enumerated() {
              let lnPayment = LNPayment(paymentHash: payment.paymentHash,
                                        value: Int(payment.value),
                                        creationDate: Int(payment.creationDate),
                                        path: payment.path,
                                        fee: Int(payment.fee),
                                        paymentPreimage: payment.paymentPreimage)
              
              lnPayments.append(lnPayment)
              
              SLLog.verbose("")
              SLLog.verbose("Lightning Payment #\(index)")
              SLLog.verbose(String(describing: lnPayment))
            }
            
            // Success! - dereference retry
            retry.success()
            completion({ return lnPayments })
            
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
      SLLog.warning("List LN Payments Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    retry.start("List LN Payments", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: Stop Daemon
  
  static func stopDaemon(completion: @escaping (() throws -> ()) -> Void) throws {
    try prepareLightningService()
    
    // Unary GRPC
    _ = try lightningService!.stopDaemon(Lnrpc_StopRequest()) { (response, result) in
      if response != nil {
        SLLog.debug("Stop Daemon Success!")
        completion({ return })
      } else {
        let message = result.statusMessage ?? result.description
        SLLog.warning("Stop Daemon Failed - \(message)")
        completion({ throw GRPCResultError(code: result.statusCode.rawValue, message: message) })
      }
    }
  }
  
}
