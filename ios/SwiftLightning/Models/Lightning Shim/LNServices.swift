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
    SLLog.verbose("LND Start called back with Error \(p0.localizedDescription)")
  }
  
  func onResponse(_ p0: Data!) {
    SLLog.verbose("LND Start called back with Data")
  }
}


class LNServices {
  
  // MARK: Initialization
  
  static var rpcListenPort: UInt = 10009
  static var peerListenPort: UInt = 9735
  static var restListenPort: UInt = 8080

  static var directoryPath: String = ""
  static var lndQueue: DispatchQueue?
  
  static func initialize() {
    
    getenv("HOME")
    
    // Obtain the path to Application Support
    guard let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.path else {
      SLLog.fatal("Cannot get Application Support Folder URL")
    }
    directoryPath = appSupportPath + "/lnd"

    // Get handles to source and destination lnd.conf URLs
    guard let lndSourceURL = Bundle.main.url(forResource: "lnd", withExtension: "conf") else {
      SLLog.fatal("Cannot get in Bundle lnd.conf")
    }
    let lndDestinationURL = URL(fileURLWithPath: directoryPath).appendingPathComponent("lnd.conf", isDirectory: false)

    // Check if file and directory. Create/copy as necassary
    if !FileManager.default.fileExists(atPath: lndDestinationURL.path) {
      do {
        if !FileManager.default.fileExists(atPath: directoryPath, isDirectory: nil) {
          try FileManager.default.createDirectory(atPath: directoryPath, withIntermediateDirectories: true)
        }
        try FileManager.default.copyItem(at: lndSourceURL, to: lndDestinationURL)
        usleep(100000)  // Sleep for 100ms for file to settle
      } catch CocoaError.fileWriteFileExists {
        SLLog.assert("lnd.conf already exist at Applicaiton Support/lnd")
      } catch {
        let nsError = error as NSError
        SLLog.fatal("Failed to copy lnd.conf from bundle to Application Support/lnd/lnd.conf.\(nsError.domain): \(nsError.code) - \(nsError.localizedDescription)")
      }
    }
      
    // File exists, replace if differs
    else if !FileManager.default.contentsEqual(atPath: lndSourceURL.path, andPath: lndDestinationURL.path) {
      let lndTempURL = URL(fileURLWithPath: directoryPath).appendingPathComponent("lnd.temp", isDirectory: false)
      
      // Replacement requires source to be in a local temp. And seems the temp is auto removed after
      do {
        try FileManager.default.copyItem(at: lndSourceURL, to: lndTempURL)
        _ = try FileManager.default.replaceItemAt(lndDestinationURL, withItemAt: lndTempURL, backupItemName: "lnd.bak")
        usleep(100000)  // Sleep for 100ms for file to settle
      } catch {
        let nsError = error as NSError
        SLLog.assert("Failed to replace lnd.conf. \(nsError.domain): \(nsError.code) - \(nsError.localizedDescription)")
      }
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
    
    SLLog.debug("LN Generate Seed thru GRPC")
    
    // Unary GRPC
    _ = try walletUnlockerService!.genSeed(Lnrpc_GenSeedRequest()) { (response, result) in
      if let response = response {
        SLLog.debug("LN Generate Seed Success!")
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
    
    SLLog.debug("LN Create Wallet thru GRPC")
    
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
    
    SLLog.debug("LN Unlock Wallet thru GRPC")
    
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
  
  
  // MARK: Wallet Balance
  
  private class WalletBalance: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> (total: Int, confirmed: Int, unconfirmed: Int)) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> (total: Int, confirmed: Int, unconfirmed: Int)) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      SLLog.debug("LN Wallet Balance Success!")
      
      // Dereference retry
      retry.success()
      
      guard let data = p0 else {
        SLLog.warning("Data p0 = nil")
        completion({ return (0 , 0, 0) })
        return
      }
      
      do {
        let response = try Lnrpc_WalletBalanceResponse(serializedData: data)
        let totalBalance = Int(response.totalBalance)
        let confirmedBalance = Int(response.confirmedBalance)
        let unconfirmedBalance = Int(response.unconfirmedBalance)
        
        SLLog.verbose("Total Balance: \(response.totalBalance)")
        SLLog.verbose("Confirmed Balance: \(response.confirmedBalance)")
        SLLog.verbose("Unconfirmed Balance: \(response.unconfirmedBalance)")
        
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
        SLLog.debug("LN Wallet Balance Request")
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
  
  private class ChannelBalance: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> (confirmed: Int, pendingOpen: Int)) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> (confirmed: Int, pendingOpen: Int)) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      SLLog.debug("LN Channel Balance Success!")
      
      // Dereference retry
      retry.success()
      
      guard let data = p0 else {
        SLLog.warning("Data p0 = nil")
        completion({ return (0 , 0) })
        return
      }
      
      do {
        let response = try Lnrpc_ChannelBalanceResponse(serializedData: data)
        SLLog.verbose("Channel Balance: \(response.balance), Pending Balance: \(response.pendingOpenBalance)")
        completion({ return (Int(response.balance), Int(response.pendingOpenBalance)) })
      } catch {
        completion({ throw error })
      }
    }
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  static func channelBalance(retryCount: Int = LNConstants.defaultRetryCount,
                            retryDelay: Double = LNConstants.defaultRetryDelay,
                            completion: @escaping (() throws -> (confirmed: Int, pendingOpen: Int)) -> Void) {
    let lndOp = ChannelBalance(completion)
    
    let task = {
      do {
        SLLog.debug("LN Channel Balance Request")
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
  
  private class GetTransactions: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> ([BTCTransaction])) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> ([BTCTransaction])) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      SLLog.debug("Get Bitcoin Transactions Success!")
      
      // Dereference retry
      retry.success()
      var btcTransactions = [BTCTransaction]()
      
      guard let data = p0 else {
        SLLog.warning("Data p0 = nil")
        completion({ return btcTransactions })
        return
      }
      
      do {
        let response = try Lnrpc_TransactionDetails(serializedData: data)
        
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
        
        completion({ return btcTransactions })
      } catch {
        completion({ throw error })
      }
    }
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  static func getTransactions(retryCount: Int = LNConstants.defaultRetryCount,
                              retryDelay: Double = LNConstants.defaultRetryDelay,
                              completion: @escaping (() throws -> ([BTCTransaction])) -> Void) {
    let lndOp = GetTransactions(completion)
    
    let task = {
      do {
        SLLog.debug("LN Get Transactions Request")
        let request = try Lnrpc_GetTransactionsRequest().serializedData()
        LndmobileGetTransactions(request, lndOp)
      } catch {
        completion({ throw error })
      }
    }
    
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Get Transactions Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    lndOp.retry.start("LN Get Transactions", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
  
  
  // MARK: Send Coins
  
  private class SendCoins: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> (String)) -> Void
    init(_ completion: @escaping (() throws -> (String)) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        let response = try Lnrpc_SendCoinsResponse(serializedData: p0)
        SLLog.debug("LN Send Coins Success!")
        
        completion({ response.txid })
      } catch {
        completion({ throw error })
      }
    }
    func onError(_ p0: Error!) { completion({ throw p0 }) }
  }
  
  static func sendCoins(address: String, amount: Int, targetConf: Int? = nil, satPerByte: Int? = nil,
                        retryCount: Int = LNConstants.defaultRetryCount,
                        retryDelay: Double = LNConstants.defaultRetryDelay,
                        completion: @escaping (() throws -> (String)) -> Void) {
    
    // Not retrying anything that draws funds
    let lndOp = SendCoins(completion)

    do {
      var request = Lnrpc_SendCoinsRequest()
      request.addr = address
      request.amount = Int64(amount)
      
      if let targetConf = targetConf { request.targetConf = Int32(targetConf) }
      if let satPerByte = satPerByte { request.satPerByte = Int64(satPerByte) }
      
      SLLog.debug("LN Send Coins Request to \(request.addr.prefix(10))...")
      let serialReq = try request.serializedData()
      LndmobileSendCoins(serialReq, lndOp)
    } catch {
      completion({ throw error })
    }
  }
  
  
  // MARK: Subscribe Transactions
  
  private class SubscribeTransactions: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> (BTCTransaction)) -> Void
    
    init(_ completion: @escaping (() throws -> (BTCTransaction)) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        let transaction = try Lnrpc_Transaction(serializedData: p0)
        SLLog.debug("LN Transaction Broadcasted")
        
        let btcTransaction = BTCTransaction(txHash: transaction.txHash,
                                            amount: Int(transaction.amount),
                                            numConfirmations: Int(transaction.numConfirmations),
                                            blockHash: transaction.blockHash,
                                            blockHeight: Int(transaction.blockHeight),
                                            timeStamp: Int(transaction.timeStamp),
                                            totalFees: Int(transaction.totalFees),
                                            destAddresses: transaction.destAddresses)
        
        SLLog.verbose(String(describing: btcTransaction))
        completion({ return btcTransaction })
      } catch {
        completion({ throw error })
      }
    }
    
    func onError(_ p0: Error!) {
      if p0.localizedDescription != "EOF" {
        completion({ throw p0 })
      }
    }
  }
  
  static func subscribeTransactions(retryCount: Int = LNConstants.defaultRetryCount,
                                    retryDelay: Double = LNConstants.defaultRetryDelay,
                                    completion: @escaping (() throws -> (BTCTransaction)) -> Void) {
    
    let lndOp = SubscribeTransactions(completion)
    SLLog.debug("LN Subscribe Transactions Request")
    LndmobileSubscribeTransactions(nil, lndOp)
  }
  
  
  // MARK: New Address
  
  private class NewAddress: NSObject, LndmobileCallbackProtocol {
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
  
  static func newAddress(type addressType: OnChainAddressType,
                         retryCount: Int = LNConstants.defaultRetryCount,
                         retryDelay: Double = LNConstants.defaultRetryDelay,
                         completion: @escaping (() throws -> (String)) -> Void) {
    
    let lndOp = NewAddress(completion)
    
    let task = {
      do {
        var request = Lnrpc_NewAddressRequest()
        
        switch addressType {
        case .p2wkh:
          request.type = .witnessPubkeyHash
        case .np2wkh:
          request.type = .nestedPubkeyHash
        default:
          throw LNError.addressTypeUnsupported
        }
        
        SLLog.debug("LN New Address Request")
        let serialReq = try request.serializedData()
        LndmobileNewAddress(serialReq, lndOp)
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
  
  private class ConnectPeer: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> ()) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> ()) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      //!!! Connect Peer does not return any data
      SLLog.debug("LN Connect Peer Success!")
      
      retry.success()
      completion({ return })
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
        
        SLLog.debug("LN Connect Peer Request - PubKey: \(pubKey.prefix(10))..., Addr: \(hostAddr):\(hostPort)")
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
  
  private class ListPeers: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> ([LNPeer])) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> ([LNPeer])) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      SLLog.debug("LN List Peers Success!")
      
      // Success! - dereference retry
      retry.success()
      var lnPeers = [LNPeer]()
      
      guard let data = p0 else {
        SLLog.warning("Data p0 = nil")
        completion({ return lnPeers })
        return
      }
      
      do {
        let response = try Lnrpc_ListPeersResponse(serializedData: data)

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
        SLLog.debug("LN List Peers Request")
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
  
  private class GetInfo: NSObject, LndmobileCallbackProtocol {
    
    private var completion: (() throws -> (LNDInfo)) -> Void
    let retry = SLRetry()
    
    init(_ completion: @escaping (() throws -> (LNDInfo)) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        let response = try Lnrpc_GetInfoResponse(serializedData: p0)
        SLLog.verbose("LN Get Info Success!")  // Changing to verbose because this can get triggered a lot
        
        let lndInfo = LNDInfo(identityPubkey: response.identityPubkey,
                              alias: response.alias,
                              numPendingChannels: UInt(response.numPendingChannels),
                              numActiveChannels: UInt(response.numActiveChannels),
                              numPeers: UInt(response.numPeers),
                              blockHeight: UInt(response.blockHeight),
                              blockHash: response.blockHash,
                              syncedToChain: response.syncedToChain,
                              testnet: response.testnet,
                              chains: response.chains,
                              uris: response.uris,
                              bestHeaderTimestamp: Int(response.bestHeaderTimestamp),
                              version: response.version)
        
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
        SLLog.debug("LN Get Info Request")
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
  
  private class PendingChannels: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> (pendingOpen: [LNPendingOpenChannel], pendingClose: [LNPendingCloseChannel], pendingForceClose: [LNPendingForceCloseChannel], waitingClose: [LNWaitingCloseChannel])) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> (pendingOpen: [LNPendingOpenChannel], pendingClose: [LNPendingCloseChannel], pendingForceClose: [LNPendingForceCloseChannel], waitingClose: [LNWaitingCloseChannel])) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      SLLog.debug("LN Pending Channels Success!")
      
      // Dereference retry
      retry.success()
      var lnPendingOpenChannels = [LNPendingOpenChannel]()
      var lnPendingCloseChannels = [LNPendingCloseChannel]()
      var lnPendingForceCloseChannels = [LNPendingForceCloseChannel]()
      var lnWaitingCloseChannels = [LNWaitingCloseChannel]()
      
      guard let data = p0 else {
        SLLog.warning("Data p0 = nil")
        completion({ return (lnPendingOpenChannels, lnPendingCloseChannels, lnPendingForceCloseChannels, lnWaitingCloseChannels) })
        return
      }
      
      do {
        let response = try Lnrpc_PendingChannelsResponse(serializedData: data)
        
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
        
        for (index, waitingCloseChannel) in response.waitingCloseChannels.enumerated() {
          
          let lnPendingChannel = LNPendingChannel(remoteNodePub: waitingCloseChannel.channel.remoteNodePub,
                                                  channelPoint: waitingCloseChannel.channel.channelPoint,
                                                  capacity: Int(waitingCloseChannel.channel.capacity),
                                                  localBalance: Int(waitingCloseChannel.channel.localBalance),
                                                  remoteBalance: Int(waitingCloseChannel.channel.remoteBalance))
          
          let lnWaitingCloseChannel = LNWaitingCloseChannel(channel: lnPendingChannel,
                                                            hasChannel: waitingCloseChannel.hasChannel,
                                                            limboBalance: Int(waitingCloseChannel.limboBalance))
          lnWaitingCloseChannels.append(lnWaitingCloseChannel)
          
          SLLog.verbose("")
          SLLog.verbose("Waiting Close Channel #\(index)")
          SLLog.verbose(String(describing: lnWaitingCloseChannel))
        }

        completion({ return (lnPendingOpenChannels, lnPendingCloseChannels, lnPendingForceCloseChannels, lnWaitingCloseChannels) })
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
                                                                   pendingForceClose: [LNPendingForceCloseChannel],
                                                                   waitingClose: [LNWaitingCloseChannel])) -> Void) {
    
    let lndOp = PendingChannels(completion)
    
    let task = {
      do {
        SLLog.debug("LN Pending Channels Request")
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
  
  private class ListChannels: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> ([LNChannel])) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> ([LNChannel])) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      SLLog.debug("LN List Channels Success!")
      
      // Dereference retry
      retry.success()
      var lnChannels = [LNChannel]()
      
      guard let data = p0 else {
        SLLog.warning("Data p0 = nil")
        completion({ return lnChannels })
        return
      }
      
      do {
        let response = try Lnrpc_ListChannelsResponse(serializedData: data)
        
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
        SLLog.debug("LN List Channels Request")
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
  
  private class OpenChannel: NSObject, LndmobileCallbackProtocol {
    var completion: ((() throws -> (LNOpenChannelUpdateType)) -> Void)?
    var timeoutSemaphore = DispatchSemaphore(value: 1)
    var timeoutWorkItem: DispatchWorkItem?
    
    init(_ completion: @escaping (() throws -> (LNOpenChannelUpdateType)) -> Void) {
      self.completion = completion
    }
    func timeout() {
      timeoutSemaphore.wait()
      completion?({ throw LNError.closeChannelTimeoutError })
      completion = nil
      timeoutWorkItem = nil
      timeoutSemaphore.signal()
    }
    func timeoutCancel() {
      timeoutSemaphore.wait()
      timeoutWorkItem?.cancel()
      timeoutWorkItem = nil
      timeoutSemaphore.signal()
    }
    func onResponse(_ p0: Data!) {
      // Got a response, cancel the timeout
      timeoutCancel()
      
      do {
        let response = try Lnrpc_OpenStatusUpdate(serializedData: p0)
        SLLog.debug("Open Channel Status Update")
        
        guard let update = response.update else {
          SLLog.warning("LN Open Channel call stream result with no type")
          completion?({ throw LNError.openChannelStreamNoType })
          return
        }
        
        switch update {
        case .chanPending(let pendingUpdate):
          SLLog.verbose("LN Open Channel Pending Update:")
          SLLog.verbose(" TXID:          \(pendingUpdate.txid.hexEncodedString(options: .littleEndian))")
          SLLog.verbose(" Output Index:  \(pendingUpdate.outputIndex)")
          completion?({ return LNOpenChannelUpdateType.pending })
          
        case .confirmation(let confirmUpdate):
          SLLog.verbose("LN Open Channel Confirmation Update:")
          SLLog.verbose(" Block SHA:          \(confirmUpdate.blockSha.hexEncodedString(options: .littleEndian))")
          SLLog.verbose(" Block Height:       \(confirmUpdate.blockHeight)")
          SLLog.verbose(" Num of Confs Left:  \(confirmUpdate.numConfsLeft)")
          completion?({ return LNOpenChannelUpdateType.confirmation })
          
        case .chanOpen(let openUpdate):
          SLLog.verbose("LN Open Channel Open Update:")
          SLLog.verbose(" TXID:          \(openUpdate.channelPoint.fundingTxidStr)")
          SLLog.verbose(" Output Index:  \(openUpdate.channelPoint.outputIndex)")
          completion?({ return LNOpenChannelUpdateType.opened })
        }
        
      } catch {
        SLLog.warning("Open channel response is not OpenStatusUpdate?")
        completion?({ throw error })
      }
    }
    
    func onError(_ p0: Error!) {
      timeoutCancel()
      
      if p0.localizedDescription != "EOF" {
        SLLog.warning("OpenChannel error response - \(p0.localizedDescription)")
        completion?({ throw p0 })
      } else {
        SLLog.info("Open Channel EOF")
      }
    }
  }
  
  static func openChannel(nodePubKey: Data, localFundingAmt: Int, pushSat: Int, targetConf: Int? = nil, satPerByte: Int? = nil,
                          retryCount: Int = LNConstants.defaultRetryCount,
                          retryDelay: Double = LNConstants.defaultRetryDelay,
                          completion: @escaping (() throws -> (LNOpenChannelUpdateType)) -> Void) {
    // Time-out routine
    let lndOp = OpenChannel(completion)
    lndOp.timeoutWorkItem = DispatchWorkItem { lndOp.timeout() }
    
    var request = Lnrpc_OpenChannelRequest()
    request.nodePubkey = nodePubKey
    request.localFundingAmount = Int64(localFundingAmt)
    request.pushSat = Int64(pushSat)

    if let targetConf = targetConf { request.targetConf = Int32(targetConf) }
    if let satPerByte = satPerByte { request.satPerByte = Int64(satPerByte) }
  
    do {
      SLLog.info("LN Open Channel Request - PubKey: \(nodePubKey.hexEncodedString().prefix(10))...")
      let serialReq = try request.serializedData()
      
      // Initiate timeout before issuing the request
      DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + LNConstants.defaultChannelOpTimeout, execute: lndOp.timeoutWorkItem!)
      LndmobileOpenChannel(serialReq, lndOp)
    } catch {
      completion({ throw error })
    }
  }


  // MARK: Close Channel
  
  private class CloseChannel: NSObject, LndmobileCallbackProtocol {
    var completion: ((() throws -> (LNCloseChannelUpdateType)) -> Void)?
    var timeoutSemaphore = DispatchSemaphore(value: 1)
    var timeoutWorkItem: DispatchWorkItem?
    
    init(_ completion: @escaping (() throws -> (LNCloseChannelUpdateType)) -> Void) {
      self.completion = completion
    }
    func timeout() {
      timeoutSemaphore.wait()
      completion?({ throw LNError.closeChannelTimeoutError })
      completion = nil
      timeoutWorkItem = nil
      timeoutSemaphore.signal()
    }
    func timeoutCancel() {
      timeoutSemaphore.wait()
      timeoutWorkItem?.cancel()
      timeoutWorkItem = nil
      timeoutSemaphore.signal()
    }
    func onResponse(_ p0: Data!) {
      // Got a response, cancel the timeout
      timeoutCancel()
      
      do {
        let response = try Lnrpc_CloseStatusUpdate(serializedData: p0)
        SLLog.debug("Close Channel Status Update")
        
        guard let update = response.update else {
          SLLog.warning("LN Close Channel call stream result with no type")
          completion?({ throw LNError.closeChannelStreamNoType })
          return
        }
        
        switch update {
        case .closePending(let pendingUpdate):
          SLLog.verbose("LN Close Channel Pending Update:")
          SLLog.verbose(" TXID:          \(pendingUpdate.txid.hexEncodedString(options: .littleEndian))")
          SLLog.verbose(" Output Index:  \(pendingUpdate.outputIndex)")
          completion?({ return LNCloseChannelUpdateType.pending })
          
        case .confirmation(let confirmUpdate):
          SLLog.verbose("LN Close Channel Confirmation Update:")
          SLLog.verbose(" Block SHA:          \(confirmUpdate.blockSha.hexEncodedString(options: .littleEndian))")
          SLLog.verbose(" Block Height:       \(confirmUpdate.blockHeight)")
          SLLog.verbose(" Num of Confs Left:  \(confirmUpdate.numConfsLeft)")
          completion?({ return LNCloseChannelUpdateType.confirmation })
          
        case .chanClose(let closeUpdate):
          SLLog.verbose("LN Close Channel Open Update:")
          SLLog.verbose(" Close TxID:          \(closeUpdate.closingTxid.hexEncodedString())")
          SLLog.verbose(" Success:  \(closeUpdate.success)")
          completion?({ return LNCloseChannelUpdateType.closed })
        }
        
      } catch {
        SLLog.warning("Close channel response is not CloseStatusUpdate?")
        completion?({ throw error })
      }
    }
    func onError(_ p0: Error!) {
      timeoutCancel()
      
      if p0.localizedDescription != "EOF" {
        SLLog.warning("CloseChannel error response - \(p0.localizedDescription)")
        completion?({ throw p0 })
      } else {
        SLLog.info("Close Channel EOF")
      }
    }
  }
  
  static func closeChannel(fundingTxIDStr: String, outputIndex: UInt, force: Bool,
                           targetConf: Int? = nil, satPerByte: Int? = nil,
                           retryCount: Int = LNConstants.defaultRetryCount,
                           retryDelay: Double = LNConstants.defaultRetryDelay,
                           completion: @escaping (() throws -> (LNCloseChannelUpdateType)) -> Void) {
    
    let lndOp = CloseChannel(completion)
    lndOp.timeoutWorkItem = DispatchWorkItem { lndOp.timeout() }
    
    var channelPoint = Lnrpc_ChannelPoint()
    channelPoint.fundingTxidStr = fundingTxIDStr
    channelPoint.outputIndex = UInt32(outputIndex)
    
    var request = Lnrpc_CloseChannelRequest()
    request.channelPoint = channelPoint
    request.force = force
    
    if let targetConf = targetConf { request.targetConf = Int32(targetConf) }
    if let satPerByte = satPerByte { request.satPerByte = Int64(satPerByte) }
    
    do {
      SLLog.info("LN Close Channel Request - PubKey: \(fundingTxIDStr.prefix(10))...")
      let serialReq = try request.serializedData()
      
      // Initiate timeout before issuing the request
      DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + LNConstants.defaultChannelOpTimeout, execute: lndOp.timeoutWorkItem!)
      LndmobileCloseChannel(serialReq, lndOp)
    } catch {
      completion({ throw error })
    }
  }
  
  
  // MARK: Send Payment Sync
  
  private class SendPaymentSync: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> (payError: String, payPreImage: Data, payRoute: LNRoute)) -> Void
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
                            expiry: UInt(hop.expiry),
                            amtToForwardMsat: Int(hop.amtToForwardMsat),
                            feeMsat: Int(hop.feeMsat))
          lnHops.append(lnHop)
        }
        
        let lnRoute = LNRoute(totalTimeLock: UInt(response.paymentRoute.totalTimeLock),
                              totalFees: Int(response.paymentRoute.totalFees),
                              totalAmt: Int(response.paymentRoute.totalAmt),
                              hops: lnHops,
                              totalFeesMsat: Int(response.paymentRoute.totalFeesMsat),
                              totalAmtMsat: Int(response.paymentRoute.totalAmtMsat))
        
        completion({ return (response.paymentError, response.paymentPreimage, lnRoute) })
      } catch {
        completion({ throw error })
      }
    }
    func onError(_ p0: Error!) { completion({ throw p0 }) }
  }
  
  static func sendPaymentSync(dest: Data? = nil, amount: Int? = nil, payHash: Data? = nil, payReq: String? = nil, finalCLTVDelta: Int? = nil,
                              retryCount: Int = LNConstants.defaultRetryCount,
                              retryDelay: Double = LNConstants.defaultRetryDelay,
                              completion: @escaping (() throws -> (payError: String, payPreImage: Data, payRoute: LNRoute)) -> Void) {
    
    // Not retrying anything that draws funds
    let lndOp = SendPaymentSync(completion)
    
    do {
      var request = Lnrpc_SendRequest()
      if let dest = dest {
        request.dest = dest
        SLLog.info("LN Send Payment Sync Request - Dest: \(dest.hexEncodedString().prefix(10))...")
      }
      if let amount = amount { request.amt = Int64(amount) }
      if let payHash = payHash { request.paymentHash = payHash }
      if let payReq = payReq {
        request.paymentRequest = payReq
        SLLog.info("LN Send Payment Sync Request - PayReq: \(payReq.prefix(10))...")
      }
      if let finalCTLVDelta = finalCLTVDelta { request.finalCltvDelta = Int32(finalCTLVDelta) }
      
      let serialReq = try request.serializedData()
      LndmobileSendPaymentSync(serialReq, lndOp)
    } catch {
      completion({ throw error })
    }
  }
  
  
  // MARK: Get Node Info
  
  private class GetNodeInfo: NSObject, LndmobileCallbackProtocol {
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
        
        SLLog.info("LN Get Node Info Request - PubKey: \(pubKey.prefix(10))...")
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
  
  private class QueryRoutes: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> ([LNRoute])) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> ([LNRoute])) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      SLLog.debug("LN Query Routes Success!")
      
      // Success! - dereference retry
      retry.success()
      var lnRoutes = [LNRoute]()
      
      guard let data = p0 else {
        SLLog.warning("Data p0 = nil")
        completion({ return lnRoutes })
        return
      }
      
      do {
        let response = try Lnrpc_QueryRoutesResponse(serializedData: data)
        for route in response.routes {
          
          var lnHops = [LNHop]()
          for hop in route.hops {
            lnHops.append(LNHop(chanID: UInt(hop.chanID),
                                chanCapacity: Int(hop.chanCapacity),
                                amtToForward: Int(hop.amtToForward),
                                fee: Int(hop.fee),
                                expiry: UInt(hop.expiry),
                                amtToForwardMsat: Int(hop.amtToForwardMsat),
                                feeMsat: Int(hop.feeMsat)))
          }
          
          lnRoutes.append(LNRoute(totalTimeLock: UInt(route.totalTimeLock),
                                  totalFees: Int(route.totalFees),
                                  totalAmt: Int(route.totalAmt),
                                  hops: lnHops,
                                  totalFeesMsat: Int(route.totalFeesMsat),
                                  totalAmtMsat: Int(route.totalAmtMsat)))
        }
        
        SLLog.verbose("")
        SLLog.verbose(String(describing: lnRoutes))

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
        
        SLLog.info("LN Query Routes Request - PubKey: \(pubKey.prefix(10))...")
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
  
  private class DecodePayReq: NSObject, LndmobileCallbackProtocol {
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
        
        SLLog.info("LN Decode Pay Req Request - PayReq: \(payReqInput.prefix(10))...")
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
  
  private class ListPayments: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> ([LNPayment])) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> ([LNPayment])) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      SLLog.debug("List LN Payments Success!")
      
      // Success! - dereference retry
      retry.success()
      var lnPayments = [LNPayment]()
      
      guard let data = p0 else {
        SLLog.warning("Data p0 = nil")
        completion({ return lnPayments })
        return
      }
      
      do {
        let response = try Lnrpc_ListPaymentsResponse(serializedData: data)

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
        SLLog.debug("LN List Payments Request")
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
  
  private class StopDaemon: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> ()) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> ()) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        if let p0 = p0 {
          _ = try Lnrpc_StopResponse(serializedData: p0)
        } else {
          SLLog.warning("Stop Daemon response does not return any data!!!")
        }
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
        SLLog.debug("LN Stop Daemon")
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
  
  
  // MARK: Subscribe Channel Graph
  
  private class SubscribeChannelGraph: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> ([LNGraphTopologyUpdate])) -> Void
    
    init(_ completion: @escaping (() throws -> ([LNGraphTopologyUpdate])) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        let graphTopologyUpdate = try Lnrpc_GraphTopologyUpdate(serializedData: p0)
        SLLog.debug("LN Graph Topology Update Received")
        
        var lnUpdates = [LNGraphTopologyUpdate]()
        
        for update in graphTopologyUpdate.nodeUpdates {
          let lnUpdate = LNGraphTopologyUpdate.node(update.identityKey)
          lnUpdates.append(lnUpdate)
          SLLog.verbose(String(describing: lnUpdate))
        }
        
        for update in graphTopologyUpdate.channelUpdates {
          let channelPoint = "\(update.chanPoint.fundingTxidBytes.hexEncodedString()):\(update.chanPoint.outputIndex)"
          let lnUpdate = LNGraphTopologyUpdate.channel(channelPoint)
          lnUpdates.append(lnUpdate)
          SLLog.verbose(String(describing: lnUpdate))
        }

        for update in graphTopologyUpdate.closedChans {
          let channelPoint = "\(update.chanPoint.fundingTxidBytes.hexEncodedString()):\(update.chanPoint.outputIndex)"
          let lnUpdate = LNGraphTopologyUpdate.channel(channelPoint)
          lnUpdates.append(lnUpdate)
          SLLog.verbose(String(describing: lnUpdate))
        }
        
        completion({ return lnUpdates })
      } catch {
        completion({ throw error })
      }
    }
    
    func onError(_ p0: Error!) {
      if p0.localizedDescription != "EOF" {
        completion({ throw p0 })
      }
    }
  }
  
  static func subscribeChannelGraph(retryCount: Int = LNConstants.defaultRetryCount,
                                    retryDelay: Double = LNConstants.defaultRetryDelay,
                                    completion: @escaping (() throws -> ([LNGraphTopologyUpdate])) -> Void) {
    
    let lndOp = SubscribeChannelGraph(completion)
    SLLog.debug("LN Subscribe Channel Graph Request")
    LndmobileSubscribeChannelGraph(nil, lndOp)
  }
  
  
  // MARK: Debug Level

  private class DebugLevel: NSObject, LndmobileCallbackProtocol {
    private var completion: (() throws -> (String)) -> Void
    let retry = SLRetry()
    init(_ completion: @escaping (() throws -> (String)) -> Void) {
      self.completion = completion
    }
    
    func onResponse(_ p0: Data!) {
      do {
        let response = try Lnrpc_DebugLevelResponse(serializedData: p0)
        SLLog.debug("LN Debug Level Success!")
        SLLog.verbose("\(response.subSystems)")
        completion({ return response.subSystems })
      } catch {
        completion({ throw error })
      }
    }
    func onError(_ p0: Error!) { retry.attempt(error: p0) }
  }
  
  static func debugLevel(show: Bool = false, levelSpec: String = "",
                         retryCount: Int = LNConstants.defaultRetryCount,
                         retryDelay: Double = LNConstants.defaultRetryDelay,
                         completion: @escaping (() throws -> (String)) -> Void) {
    
    let lndOp = DebugLevel(completion)
    
    let task = {
      do {
        var request = Lnrpc_DebugLevelRequest()
        request.show = show
        request.levelSpec = levelSpec
        
        SLLog.debug("LN Debug Level Request")
        let serialReq = try request.serializedData()
        LndmobileDebugLevel(serialReq, lndOp)
      } catch {
        completion({ throw error })
      }
    }
    
    let fail = { (error: Error) -> () in
      SLLog.warning("LN Debug Level Failed - \(error.localizedDescription)")
      completion({ throw error })
    }
    
    lndOp.retry.start("LN Debug Level", withCountOf: retryCount, withDelayOf: retryDelay, taskBlock: task, failBlock: fail)
  }
}
