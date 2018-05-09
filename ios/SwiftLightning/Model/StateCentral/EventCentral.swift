//
//  EventCentral.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-05-04.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation

class EventCentral {
  
  struct Constants {
    static let timeIntervalPerBlk: Double = 600  // Mainnet only!!!
    static let testnet3Blk1Timestamp: Double = 1296688928   // Testnet 3 only!!!
    static let syncMonitorInterval: Double = 1 // seconds
  }
  
  
  // MARK: Singleton Instantiation
  
  static let shared = EventCentral()
  
  private init() { }
  
  
  // MARK: Sync Progress Monitoring
  
  // SyncUpdateCallback is guarenteed to be called at least once
  private var syncUpdateCallback: ((Bool, Double, Date) -> ())?
  private var syncTimer: RepeatingTimer?
  
  
  func start(proceed: @escaping (Result<Void>) -> ()) {
    // Increase retry count because unlock can take a while
    // Decrease retry delay so unlock process is more responsive
    LNServices.getInfo(retryCount: 20, retryDelay: 0.5) { (responder) in
      do {
        let info = try responder()
        
        if info.syncedToChain {
          // Just directly start Event Relayer
          self.startEventRelayer()
          
        } else {
          // Start Sync Progress Monitor
          self.syncTimer = RepeatingTimer(timeInterval: Constants.syncMonitorInterval)
          self.syncTimer!.eventHandler = {
            self.syncTimerHandler(for: self.syncTimer)
          }
          self.syncTimer!.resume()
        }
        proceed(Result<Void>.success(()))
        
      } catch {
        proceed(Result<Void>.failure(error))
      }
    }
  }
  
  private func syncTimerHandler(for timer: RepeatingTimer?) {
    LNServices.getInfo(retryCount: 0, retryDelay: 1.0) { (responder) in
      do {
        let info = try responder()
        
        if info.syncedToChain {
          
          SLLog.debug("Synced to chain, invalidating Timer")
          if let timer = timer {
            timer.suspend()
            
            // Need to nil both to break reference loop
            timer.eventHandler = nil
            self.syncTimer = nil
          }
          
          self.syncUpdateCallback?(true, 1.0, Date(timeIntervalSince1970: TimeInterval(info.bestHeaderTimestamp)))
          
          // Start Event Relayer if not already started
          self.startEventRelayer()
          
        } else {
          // Update progress with callback until syncedToChain = true
          let estimate = self.estimatePercentage(blockTimestamp: info.bestHeaderTimestamp, blockHeight: info.blockHeight)
          
          SLLog.verbose("Sycn progress estiamted at \(estimate * 100.0)%")
          self.syncUpdateCallback?(false, estimate, Date(timeIntervalSince1970: TimeInterval(info.bestHeaderTimestamp)))
        }
      } catch {
        SLLog.warning("SyncTimer expiry cannot GetInfo with error - \(error.localizedDescription)")
      }
    }
  }
  
  private func estimatePercentage(blockTimestamp: Int, blockHeight: UInt) -> Double {
    
    // For Mainnet
//    let dateForBlock = Date(timeIntervalSince1970: TimeInterval(blockTimestamp))
//    let remainingInterval = abs(dateForBlock.timeIntervalSinceNow)
//    let remainingBlocks = remainingInterval/Constants.timeIntervalPerBlk
//    var estimate = Double(blockHeight)/(remainingBlocks + Double(blockHeight))
    
    // For Testnet 3
    let dateForBlock = Date(timeIntervalSince1970: TimeInterval(blockTimestamp))
    let dateForBlock1 = Date(timeIntervalSince1970: Constants.testnet3Blk1Timestamp)
    let elapsedInterval = dateForBlock.timeIntervalSince(dateForBlock1)
    let remainingInterval = abs(dateForBlock.timeIntervalSinceNow)
    var estimate = elapsedInterval/(elapsedInterval + remainingInterval)
    
    if estimate < 0.0 { estimate = 0.0 }
    if estimate >= 1.0 { estimate = 0.99 }  // Don't let it get to 1.0
    return estimate
  }
  
  func regsiterSyncProgress(callback: @escaping (Bool, Double, Date) -> ()) {
    syncUpdateCallback = callback
    
    // Make sure syncUpdateCallback gets called at least once
    syncTimerHandler(for: nil)
  }
  
  
  // MARK: Event Relayer
  //
  //   Relays the following events:
  //
  // - Transaction Subscription (onChain) Stream
  // - Invoice Subscription (Lightning) Stream
  // - OpenChannel Stream
  // - CloseChannel Stream
  //
  // * Event Relayer does not guarentee that events might not be missed
  
  private var transactionListeners = [Int : (BTCTransaction) -> ()]()
  private var channelOpenUpdateListeners = [Int : () -> ()]()
  private var channelCloseUpdateListeners = [Int : () -> ()]()
  
  private let idLock = DispatchSemaphore(value: 1)
  private let relayQueue = DispatchQueue(label: "EventRelay", qos: .background)  // not concurrent, so serial
  
  private var relayerStarted = false
  private var identifier = 0
  
  
  private func startEventRelayer() {
    guard !relayerStarted else { return }
    relayerStarted = true
    SLLog.debug("Starting Event Relayer")
    
    // Start All Subscriptions
    LNServices.subscribeTransactions(completion: transactionNotify)
  }

  
  // MARK: Functions to notify Relayer
  
  private func transactionNotify(responder: () throws -> (BTCTransaction)) {
    do {
      let transaction = try responder()
      
      relayQueue.async {
        for listener in self.transactionListeners {
          listener.value(transaction)
        }
      }
    } catch {
      SLLog.assert("Transaction Notify Error - \(error)")
    }
  }
  
  func channelOpenNotify() {
    relayQueue.async {
      for listener in self.channelOpenUpdateListeners {
        listener.value()
      }
    }
  }

  func channelCloseNotify() {
    relayQueue.async {
      for listener in self.channelCloseUpdateListeners {
        listener.value()
      }
    }
  }
  
  
  // MARK: Functions to subscribe and unsubscribe from Relays
  
  func subscribeToTransactions(with callback: @escaping (BTCTransaction) -> ()) -> Int {
    let id = getAtomicID()
    relayQueue.async { self.transactionListeners[id] = callback }
    return id
  }
  
  func unsubscribeFromTransactions(for id: Int) {
    relayQueue.async {
      self.transactionListeners.removeValue(forKey: id)
    }
  }
  
  func subscribeToChannelOpenUpdates(with callback: @escaping () -> ()) -> Int {
    let id = getAtomicID()
    relayQueue.async { self.channelOpenUpdateListeners[id] = callback }
    return id
  }
  
  func unsubscribeFromChannelOpenUpdates(for id: Int) {
    relayQueue.async {
      self.channelOpenUpdateListeners.removeValue(forKey: id)
    }
  }
  
  func subscribeToChannelCloseUpdates(with callback: @escaping () -> ()) -> Int {
    let id = getAtomicID()
    relayQueue.async { self.channelCloseUpdateListeners[id] = callback }
    return id
  }
  
  func unsubscribeFromChannelCloseUpdates(for id: Int) {
    relayQueue.async {
      self.channelCloseUpdateListeners.removeValue(forKey: id)
    }
  }
  
  private func getAtomicID() -> Int{
    idLock.wait()
    let id = identifier
    identifier += 1
    idLock.signal()
    return id
  }
}
