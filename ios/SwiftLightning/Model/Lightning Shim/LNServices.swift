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
    SLLog.verbose("LND Start calledback with Error \(p0.localizedDescription)")
  }
  
  func onResponse(_ p0: Data!) {
    SLLog.verbose("LND Start calledback with Data")
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
  
  
  // MARK: Send Coins
  
  class SendCoins: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> (String)) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> (String)) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        let response = try Lnrpc_SendCoinsResponse(serializedData: p0)
        SLLog.debug("LN Send Coins Success!")
        
        // Success. Deference retry
        retry.success()
        completion({ response.txid })
      } catch {
        completion({ throw error })
      }
    }
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  static func sendCoins(address: String, amount: Int, targetConf: Int? = nil, satPerByte: Int? = nil,
                        retryCount: Int = LNConstants.defaultRetryCount,
                        retryDelay: Double = LNConstants.defaultRetryDelay,
                        completion: @escaping (() throws -> (String)) -> Void) {
    
    let lndOp = SendCoins(completion)
    
    let task = {
      do {
        var request = Lnrpc_SendCoinsRequest()
        request.addr = address
        request.amount = Int64(amount)
        
        if let targetConf = targetConf { request.targetConf = Int32(targetConf) }
        if let satPerByte = satPerByte { request.satPerByte = Int64(satPerByte) }
        
        let serialReq = try request.serializedData()
        LndmobileSendCoins(serialReq, lndOp)
      } catch {
        completion({ throw error })
      }
    }
    
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Send Coins Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    lndOp.retry.start("LN Send Coins", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: New Address
  
  class NewAddress: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> (String)) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> (String)) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        let response = try Lnrpc_NewAddressResponse(serializedData: p0)
        SLLog.debug("LN New Address Success!")
        
        // Success! - dereference retry
        retry.success()
        completion({ return response.address })
      } catch {
        completion({ throw error })
      }
    }
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  static func newAddress(retryCount: Int = LNConstants.defaultRetryCount,
                         retryDelay: Double = LNConstants.defaultRetryDelay,
                         completion: @escaping (() throws -> (String)) -> Void) {
    
    let lndOp = NewAddress(completion)
    
    let task = {
      do {
        let request = try Lnrpc_NewAddressRequest().serializedData()
        LndmobileNewAddress(request, lndOp)
      } catch {
        completion({ throw error })
      }
    }
    
    let fail = { (error: Error) -> () in
      SLLog.warning("LN New Address Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    lndOp.retry.start("LN New Address", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: Connect Peer
  
  class ConnectPeer: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> ()) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> ()) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      // We won't retry anymore after getting here. Deference retry
      retry.success()
      
      do {
        _ = try Lnrpc_ConnectPeerResponse(serializedData: p0)
        SLLog.debug("LN Connect Peer Success!")
        
        completion({ return })
      } catch {
        completion({ throw error })
      }
    }
    
    func onError(_ p0: Error!) {
      if p0.localizedDescription.contains("already connected") {  // TODO: Hack: Is there a better way?
        // We won't retry anymore after getting here. Deference retry
        retry.success()
        
        SLLog.warning(p0.localizedDescription)
        completion({ return })
      } else {
        retry.attempt(error: p0)
      }
    }
  }
  
  static func connectPeer(pubKey: String, hostAddr: String, hostPort: Int,
                          retryCount: Int = LNConstants.defaultRetryCount,
                          retryDelay: Double = LNConstants.defaultRetryDelay,
                          completion: @escaping (() throws -> ()) -> Void) {
    
    let lndOp = ConnectPeer(completion)
    
    let task = {
      do {
        var addr = Lnrpc_LightningAddress()
        addr.pubkey = pubKey
        addr.host = "\(hostAddr):\(hostPort)"
        
        var request = Lnrpc_ConnectPeerRequest()
        request.addr = addr
        request.perm = true
        
        let serialReq = try request.serializedData()
        LndmobileConnectPeer(serialReq, lndOp)
      } catch {
        completion({ throw error })
      }
    }
    
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Connect Peer Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    lndOp.retry.start("LN Connect peer", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: List Peers
  
  class ListPeers: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> ([LNPeer])) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> ([LNPeer])) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        let response = try Lnrpc_ListPeersResponse(serializedData: p0)
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
      } catch {
        completion({ throw error })
      }
    }
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  static func listPeers(retryCount: Int = LNConstants.defaultRetryCount,
                        retryDelay: Double = LNConstants.defaultRetryDelay,
                        completion: @escaping (() throws -> ([LNPeer])) -> Void) {
    let lndOp = ListPeers(completion)
    
    let task = {
      do {
        let request = try Lnrpc_ListPeersRequest().serializedData()
        LndmobileListPeers(request, lndOp)
      } catch {
        completion({ throw error })
      }
    }
    
    let fail = { (error: Error) -> () in
      SLLog.warning("LN List Peers Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    lndOp.retry.start("LN List Peers", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
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
  
  class PendingChannels: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> (pendingOpen: [LNPendingOpenChannel], pendingClose: [LNPendingCloseChannel], pendingForceClose: [LNPendingForceCloseChannel])) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> (pendingOpen: [LNPendingOpenChannel], pendingClose: [LNPendingCloseChannel], pendingForceClose: [LNPendingForceCloseChannel])) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        let response = try Lnrpc_PendingChannelsResponse(serializedData: p0)
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
      } catch {
        completion({ throw error })
      }
    }
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  static func pendingChannels(retryCount: Int = LNConstants.defaultRetryCount,
                              retryDelay: Double = LNConstants.defaultRetryDelay,
                              completion: @escaping (() throws -> (pendingOpen: [LNPendingOpenChannel],
                                                                   pendingClose: [LNPendingCloseChannel],
                                                                   pendingForceClose: [LNPendingForceCloseChannel])) -> Void) {
    
    let lndOp = PendingChannels(completion)
    
    let task = {
      do {
        let request = try Lnrpc_PendingChannelsRequest().serializedData()
        LndmobilePendingChannels(request, lndOp)
      } catch {
        completion({ throw error })
      }
    }
    
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Pending Channels Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    lndOp.retry.start("LN Pending Channels", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: List Channels
  
  class ListChannels: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> ([LNChannel])) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> ([LNChannel])) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        let response = try Lnrpc_ListChannelsResponse(serializedData: p0)
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
      } catch {
        completion({ throw error })
      }
    }
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  static func listChannels(retryCount: Int = LNConstants.defaultRetryCount,
                           retryDelay: Double = LNConstants.defaultRetryDelay,
                           completion: @escaping (() throws -> ([LNChannel])) -> Void) {
    let lndOp = ListChannels(completion)
    
    let task = {
      do {
        let request = try Lnrpc_ListChannelsRequest().serializedData()
        LndmobileListChannels(request, lndOp)
      } catch {
        completion({ throw error })
      }
    }
    
    let fail = { (error: Error) -> () in
      SLLog.warning("LN List Channels Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    lndOp.retry.start("LN List Channels", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: Open Channel
  
  class OpenChannel: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> ()) -> Void
    let retry = SLRetry()
    
    init(_ completion: @escaping (() throws -> ()) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        _ = try Lnrpc_OpenStatusUpdate(serializedData: p0)
        SLLog.debug("response is OpenStatusUpdate")
      } catch {
        SLLog.debug("response is not OpenStatusUpdate")
      }
        
      // Success! - dereference retry
      retry.success()
      completion({ return })
    }
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  static func openChannel(nodePubKey: Data, localFundingAmt: Int, pushSat: Int, targetConf: Int? = nil, satPerByte: Int? = nil,
                          retryCount: Int = LNConstants.defaultRetryCount,
                          retryDelay: Double = LNConstants.defaultRetryDelay,
                          streaming: @escaping (() throws -> (Lnrpc_LightningOpenChannelCall)) -> Void,
                          completion: @escaping (() throws -> ()) -> Void) {
    
    let lndOp = OpenChannel(completion)
    
    let task = {
      var request = Lnrpc_OpenChannelRequest()
      request.nodePubkey = nodePubKey
      request.localFundingAmount = Int64(localFundingAmt)
      request.pushSat = Int64(pushSat)

      if let targetConf = targetConf { request.targetConf = Int32(targetConf) }
      if let satPerByte = satPerByte { request.satPerByte = Int64(satPerByte) }
    
      do {
        let serialReq = try request.serializedData()
        LndmobileOpenChannel(serialReq, lndOp)
      } catch {
        completion({ throw error })
      }
    }
    
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Open Channel Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    lndOp.retry.start("LN Open Channel", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }

  
  // MARK: Open Channel
  
  // MARK: Close Channel
  
  class CloseChannel: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> ()) -> Void
    let retry = SLRetry()
    
    init(_ completion: @escaping (() throws -> ()) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        _ = try Lnrpc_CloseStatusUpdate(serializedData: p0)
        SLLog.debug("response is CloseStatusUpdate")
      } catch {
        SLLog.debug("response is not CloseStatusUpdate")
      }
      
      // Success! - dereference retry
      retry.success()
      completion({ return })
    }
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  static func closeChannel(fundingTxIDStr: String, outputIndex: UInt, force: Bool,
                           targetConf: Int? = nil, satPerByte: Int? = nil,
                           retryCount: Int = LNConstants.defaultRetryCount,
                           retryDelay: Double = LNConstants.defaultRetryDelay,
                           completion: @escaping (() throws -> ()) -> Void) {
    
    let lndOp = CloseChannel(completion)
    
    let task = {
      var channelPoint = Lnrpc_ChannelPoint()
      channelPoint.fundingTxidStr = fundingTxIDStr
      channelPoint.outputIndex = UInt32(outputIndex)
      
      var request = Lnrpc_CloseChannelRequest()
      request.channelPoint = channelPoint
      request.force = force
      
      if let targetConf = targetConf { request.targetConf = Int32(targetConf) }
      if let satPerByte = satPerByte { request.satPerByte = Int64(satPerByte) }
      
      do {
        let serialReq = try request.serializedData()
        LndmobileCloseChannel(serialReq, lndOp)
      } catch {
        completion({ throw error })
      }
    }
    
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Close Channel Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    lndOp.retry.start("LN Close Channel", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: Send Payment Sync
  
  class SendPaymentSync: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> (payError: String, payPreImage: Data, payRoute: LNRoute)) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> (payError: String, payPreImage: Data, payRoute: LNRoute)) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        let response = try Lnrpc_SendResponse(serializedData: p0)
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
      } catch {
        completion({ throw error })
      }
    }
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  static func sendPaymentSync(dest: Data? = nil, amount: Int? = nil, payHash: Data? = nil, payReq: String? = nil, finalCLTVDelta: Int? = nil,
                              retryCount: Int = LNConstants.defaultRetryCount,
                              retryDelay: Double = LNConstants.defaultRetryDelay,
                              completion: @escaping (() throws -> (payError: String, payPreImage: Data, payRoute: LNRoute)) -> Void) {
    
    let lndOp = SendPaymentSync(completion)
    
    let task = {
      do {
        var request = Lnrpc_SendRequest()
        if let dest = dest { request.dest = dest }
        if let amount = amount { request.amt = Int64(amount) }
        if let payHash = payHash { request.paymentHash = payHash }
        if let payReq = payReq { request.paymentRequest = payReq }
        if let finalCTLVDelta = finalCLTVDelta { request.finalCltvDelta = Int32(finalCTLVDelta) }
        
        let serialReq = try request.serializedData()
        LndmobileSendPaymentSync(serialReq, lndOp)
      } catch {
        completion({ throw error })
      }
    }
    
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Send Payment Sync Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    lndOp.retry.start("LN Send Payment Sync", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: Get Node Info
  
  class GetNodeInfo: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> (LNNode)) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> (LNNode)) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        let response = try Lnrpc_NodeInfo(serializedData: p0)
        SLLog.debug("LN Get Node Info Success!")
        
        let lnNode = LNNode(lastUpdate: UInt(response.node.lastUpdate),
                            pubKey: response.node.pubKey,
                            alias: response.node.alias,
                            network: response.node.addresses.map { $0.network },
                            address: response.node.addresses.map { $0.addr },
                            color: response.node.color,
                            numChannels: UInt(response.numChannels),
                            totalCapacity: Int(response.totalCapacity))
        
        SLLog.verbose(String(describing: lnNode))
        
        // Success! - dereference retry
        retry.success()
        completion({ return lnNode })
      } catch {
        completion({ throw error })
      }
    }
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  static func getNodeInfo(pubKey: String,
                          retryCount: Int = LNConstants.defaultRetryCount,
                          retryDelay: Double = LNConstants.defaultRetryDelay,
                          completion: @escaping (() throws -> (LNNode)) -> Void) {
    let lndOp = GetNodeInfo(completion)
    
    let task = {
      do {
        var request = Lnrpc_NodeInfoRequest()
        request.pubKey = pubKey
        
        let serialReq = try request.serializedData()
        LndmobileGetNodeInfo(serialReq, lndOp)
      } catch {
        completion({ throw error })
      }
    }
    
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Get Node Info Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    lndOp.retry.start("LN Get Node Info", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: QueryRoutes
  
  class QueryRoutes: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> ([LNRoute])) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> ([LNRoute])) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        let response = try Lnrpc_QueryRoutesResponse(serializedData: p0)
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
      } catch {
        completion({ throw error })
      }
    }
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  static func queryRoutes(pubKey: String, amt: Int, numRoutes: Int,
                          retryCount: Int = LNConstants.defaultRetryCount,
                          retryDelay: Double = LNConstants.defaultRetryDelay,
                          completion: @escaping (() throws -> ([LNRoute])) -> Void) {
    
    let lndOp = QueryRoutes(completion)
    
    let task = {
      do {
        var request = Lnrpc_QueryRoutesRequest()
        request.pubKey = pubKey
        request.amt = Int64(amt)
        request.numRoutes = Int32(numRoutes)
        
        let serialReq = try request.serializedData()
        LndmobileQueryRoutes(serialReq, lndOp)
      } catch {
        completion({ throw error })
      }
    }
    
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Query Routes Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    lndOp.retry.start("LN Query Routes", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: DecodePayReq
  
  class DecodePayReq: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> (LNPayReq)) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> (LNPayReq)) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        let payReq = try Lnrpc_PayReq(serializedData: p0)
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
      } catch {
        completion({ throw error })
      }
    }
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  static func decodePayReq(_ payReqInput: String,
                           retryCount: Int = LNConstants.defaultRetryCount,
                           retryDelay: Double = LNConstants.defaultRetryDelay,
                           completion: @escaping (() throws -> (LNPayReq)) -> Void) {
    let lndOp = DecodePayReq(completion)
    
    let task = {
      do {
        var payReqString = Lnrpc_PayReqString()
        payReqString.payReq = payReqInput
        
        let request = try payReqString.serializedData()
        LndmobileDecodePayReq(request, lndOp)
      } catch {
        completion({ throw error })
      }
    }
    
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Decode Pay Req Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    lndOp.retry.start("LN Decode Pay Req", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: List Payments
  
  class ListPayments: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> ([LNPayment])) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> ([LNPayment])) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        let response = try Lnrpc_ListPaymentsResponse(serializedData: p0)
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
      } catch {
        completion({ throw error })
      }
    }
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  static func listPayments(retryCount: Int = LNConstants.defaultRetryCount,
                           retryDelay: Double = LNConstants.defaultRetryDelay,
                           completion: @escaping (() throws -> ([LNPayment])) -> Void) {
    let lndOp = ListPayments(completion)
    
    let task = {
      do {
        let request = try Lnrpc_ListPaymentsResponse().serializedData()
        LndmobileListPayments(request, lndOp)
      } catch {
        completion({ throw error })
      }
    }
    
    let fail = { (error: Error) -> () in
      SLLog.warning("LN List Payments Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    lndOp.retry.start("LN List Payments", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: Stop Daemon
  
  class StopDaemon: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> ()) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> ()) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        _ = try Lnrpc_StopResponse(serializedData: p0)
        SLLog.debug("Stop Daemon Success!")
        completion({ return })
      } catch {
        completion({ throw error })
      }
    }
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  static func stopDaemon(retryCount: Int = LNConstants.defaultRetryCount,
                         retryDelay: Double = LNConstants.defaultRetryDelay,
                         completion: @escaping (() throws -> ()) -> Void) {
    
    let lndOp = StopDaemon(completion)
    
    let task = {
      do {
        let request = try Lnrpc_StopRequest().serializedData()
        LndmobileStopDaemon(request, lndOp)
      } catch {
        completion({ throw error })
      }
    }
    
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Stop Daemon Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    lndOp.retry.start("LN Stop Daemon", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
}
