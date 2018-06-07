//
//  EventCentral.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-05-04.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit


class EventCentral {
  
  struct Constants {
    static let timeIntervalPerBlk: Double = 600  // Mainnet only!!!
    static let testnet3Blk1Timestamp: Double = 1296688928   // Testnet 3 only!!!
    static let syncMonitorInterval: Double = 3 // seconds
    static let pullUpdateInterval: Double = 60 // seconds
    static let subscribeToGraphTopology: Bool = false
  }
  
  
  // MARK: Singleton Instantiation
  
  static let shared = EventCentral()
  
  private init() { }
  
  private let eventQueue = DispatchQueue(label: "EventRelay", qos: .background)  // not concurrent, so serial
  
  
  // MARK: Atomic infinitely incrementing identifier for handles
  
  typealias Handle = Int
  
  private let idLock = DispatchSemaphore(value: 1)
  private var identifier = 0
  
  private func getAtomicID() -> Int {
    idLock.wait()
    let id = identifier
    identifier += 1
    idLock.signal()
    return id
  }
  
  
  // MARK: Sync Progress Monitoring
  
  // syncUpdateCallbacks is guarenteed to be called at least once
  private var syncUpdateCallbacks = [Handle: (Bool, Double, Date) -> ()]()
  private lazy var syncTimer: RepeatingTimer = {
    let timer = RepeatingTimer(timeInterval: Constants.syncMonitorInterval)
    timer.eventHandler = { self.syncTimerHandler() }
    return timer
  }()
  
  
  func start(proceed: @escaping (Result<Void>) -> ()) {
    // Increase retry count because unlock can take a while
    // Decrease retry delay so unlock process is more responsive
    LNServices.getInfo(retryCount: 20, retryDelay: 0.5) { (responder) in
      do {
        let info = try responder()
        
        if info.syncedToChain {
          // Reconnect all Channels if disconnected
          LNManager.reconnectAllChannels()
          
          // Just directly start Event Relayer
          self.startEventRelayer()
          
        } else {
          // Start Sync Progress Monitor
          self.syncTimer.resume()
        }
        proceed(Result<Void>.success(()))
        
      } catch {
        proceed(Result<Void>.failure(error))
      }
    }
  }
  
  private func syncTimerHandler() {
    LNServices.getInfo(retryCount: 0, retryDelay: 1.0) { (responder) in
      do {
        let info = try responder()
        
        self.eventQueue.async {
          if info.syncedToChain {
            self.syncTimer.suspend()
            
            // Allow phone to sleep if done syncing
            DispatchQueue.main.async {
              UIApplication.shared.isIdleTimerDisabled = false
            }
            
            SLLog.debug("Synced to chain!")
            
            for callback in self.syncUpdateCallbacks {
              callback.value(true, 1.0, Date(timeIntervalSince1970: TimeInterval(info.bestHeaderTimestamp)))
            }
            
            // Reconnect all Channels if disconnected
            LNManager.reconnectAllChannels()
            
            // Start Event Relayer if not already started
            self.startEventRelayer()
            
          } else {
            self.syncTimer.resume()
            
            // Prevent phone from sleeping if syncing
            DispatchQueue.main.async {
              UIApplication.shared.isIdleTimerDisabled = true
            }
            
            // Update progress with callback until syncedToChain = true
            let estimate = self.estimatePercentage(blockTimestamp: info.bestHeaderTimestamp, blockHeight: info.blockHeight)
            
            SLLog.verbose("Sycn progress estimated at \(estimate * 100.0)%")
            
            for callback in self.syncUpdateCallbacks {
              callback.value(false, estimate, Date(timeIntervalSince1970: TimeInterval(info.bestHeaderTimestamp)))
            }
          }
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
  
  func subscribeToSync(with callback: @escaping (Bool, Double, Date) -> ()) -> Handle {
    let handle: Handle = getAtomicID()
    
    eventQueue.async {
      self.syncUpdateCallbacks[handle] = callback
    
      // Make sure syncUpdateCallbacks gets called at least once
      self.syncTimerHandler()
    }
    return handle
  }
  
  func unsubscribeFromSync(on handle: Handle) {
    eventQueue.async {
      self.syncUpdateCallbacks.removeValue(forKey: handle)
    }
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
  
  enum EventType {
    case transaction
    case openUpdate
    case closeUpdate
    case nodeUpdate
    case chEdgeUpdate
    case closedChUpdate
    case periodicUpdate
  }
  
  enum Message {
    case transaction(BTCTransaction)
    case openUpdate
    case closeUpdate
    case nodeUpdate(String)  // Node Pub Key?
    case chEdgeUpdate(String)  // Channel ID
    case closeChUpdate(String)  // Channel ID
    case periodicUpdate
  }

  struct Subscription {
    var events: Set<EventType>
    var callback: (Message) -> ()
  }
  
  private var listeners = [Handle : Subscription]()
  private var relayerStarted = false
  private var periodicTimer = RepeatingTimer(timeInterval: Constants.pullUpdateInterval)
  
  private func startEventRelayer() {
    guard !relayerStarted else { return }
    relayerStarted = true
    SLLog.debug("Starting Event Relayer")
    
    // Start All Subscriptions
    LNServices.subscribeTransactions(completion: transactionNotify)
    
    if Constants.subscribeToGraphTopology {
      LNServices.subscribeChannelGraph(completion: topologyNotify)
    }
    
    // Periodic Pull Update
    periodicTimer.eventHandler = { self.periodicNotify() }
    periodicTimer.resume()
  }

  
  // MARK: Functions to notify Relayer
  
  private func transactionNotify(responder: () throws -> (BTCTransaction)) {
    do {
      let transaction = try responder()
      
      eventQueue.async {
        let txListeners = self.listeners.filter({ $0.value.events.contains(.transaction) })
        
        for listener in txListeners {
          let message = Message.transaction(transaction)
          listener.value.callback(message)
        }
      }
    } catch {
      SLLog.assert("Transaction Notify Error - \(error)")
    }
  }
  
  private func topologyNotify(responder: () throws -> ([LNGraphTopologyUpdate])) {
    do {
      let topologyUpdates = try responder()
      
      eventQueue.async {
        let nodeListeners = self.listeners.filter({ $0.value.events.contains(.nodeUpdate) })
        let channelListeners = self.listeners.filter({ $0.value.events.contains(.chEdgeUpdate) })
        let closeListeners = self.listeners.filter({ $0.value.events.contains(.closedChUpdate) })
        
        for update in topologyUpdates {
          switch update {
          case .node(let idKey):
            for listener in nodeListeners {
              let message = Message.nodeUpdate(idKey)
              listener.value.callback(message)
            }
            
          case .channel(let channelPoint):
            for listener in channelListeners {
              let message = Message.chEdgeUpdate(channelPoint)
              listener.value.callback(message)
            }
            
          case .closedChannel(let channelPoint):
            for listener in closeListeners {
              let message = Message.closeChUpdate(channelPoint)
              listener.value.callback(message)
            }
          }
        }
      }
    } catch {
      SLLog.assert("Graph Topology Notify Error - \(error)")
    }
  }
  
  private func periodicNotify() {
    eventQueue.async {
      let listeners = self.listeners.filter({ $0.value.events.contains(.periodicUpdate) })
      SLLog.debug("Periodic Pull Notification")
      
      for listener in listeners {
        let message = Message.periodicUpdate
        listener.value.callback(message)
      }
    }
  }
  
  func channelOpenNotify() {
    eventQueue.async {
      let openListeners = self.listeners.filter({ $0.value.events.contains(.openUpdate) })
      
      for listener in openListeners {
        let message = Message.openUpdate
        listener.value.callback(message)
      }
    }
  }

  func channelCloseNotify() {
    eventQueue.async {
      let closeListeners = self.listeners.filter({ $0.value.events.contains(.closeUpdate) })
      
      for listener in closeListeners {
        let message = Message.closeUpdate
        listener.value.callback(message)
      }
    }
  }
  
  
  // MARK: Functions to manage subscription to Relay
  
  func subscribe(to events: Set<EventType>, with callback: @escaping (Message) -> ()) -> Handle {
    let handle: Handle = getAtomicID()
    eventQueue.async { self.listeners[handle] = Subscription(events: events, callback: callback) }
    return handle
  }
  
  func unsubscribe(from handle: Handle) {
    eventQueue.async {
      self.listeners.removeValue(forKey: handle)
    }
  }
  
  func changeSubscription(for handle: Handle, to events: Set<EventType>, with callback: ((Message) -> ())? = nil) {
    guard self.listeners[handle] != nil else {
      SLLog.assert("No Listener for handle \(handle)")
      return
    }
    self.listeners[handle]!.events = events
    
    if let callback = callback {
      self.listeners[handle]!.callback = callback
    }
  }
  
  func getEventsSubscribed(for handle: Handle) -> Set<EventType>? {
    guard let listener = self.listeners[handle] else {
      return nil
    }
    return listener.events
  }
  

  // MARK: URL Open Events
  private var openEventURL: URL?
  
  func bufferOpenEvent(on url: URL) {
    if let openEventURL = openEventURL {
      SLLog.warning("openEventURL \(openEventURL.absoluteString) being overwritten by \(url.absoluteString)")
    }
    openEventURL = url
  }
  
  func readOpenEventURL() -> URL? {
    return openEventURL
  }
  
  func clearOpenEventURL() {
    openEventURL = nil
  }
}
