//
//  SLRetry.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-23.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation


// This retry is implemented assuming that there will be at least 1 Time-Out in the Request/Response chain. As such no time-out mechanism is needed
// This assumption might change. If so a reusable Time-out / Time-out + Retry mechanism should be built

class SLRetry {
  
  private var requestName: String!
  private var initialRetryCount: Int!
  private var retriesRemaining: Int!
  private var retryDelay: Double!  // in seconds
  private var qosLevel: DispatchQoS.QoSClass!
  private var taskBlock: (() -> Void)?
  private var failBlock: ((Error) -> Void)?
  
  func start(_ name: String,
             withCountOf count: Int,
             withDelayOf delay: Double,
             withQosOf qosLevel: DispatchQoS.QoSClass = .background,
             taskBlock: @escaping () -> Void,
             failBlock: @escaping (Error) -> Void) {
    
    self.requestName = name
    self.initialRetryCount = count
    self.retriesRemaining = count
    self.retryDelay = delay
    self.qosLevel = qosLevel
    self.taskBlock = taskBlock
    self.failBlock = failBlock
    
    // Do the initial try
    taskBlock()
  }
  
  // Attempt retry if retry count is not 0. Otherwise return False.
  func attempt(error: Error) {
    guard let taskBlock = taskBlock, let failBlock = failBlock else {
      SLLog.assert("Retry taskBlock and failBlock nil")
      return
    }
    
    // Retry remaining, lets give this another go!
    if retriesRemaining > 0 {
      SLLog.info("Retrying \(requestName!) #\(initialRetryCount - retriesRemaining + 1)/\(initialRetryCount!)")
      self.retriesRemaining = retriesRemaining - 1
      
      if retryDelay != 0 {
        DispatchQueue.global(qos: qosLevel).asyncAfter(deadline: .now() + retryDelay, execute: taskBlock)
      } else {
        DispatchQueue.global(qos: qosLevel).async(execute: taskBlock)
      }
    }
      
    // Retry count exhausted, execute prescribed failure routine.
    else {
      SLLog.warning("All \(initialRetryCount!) retry attempts of \(requestName!) exhausted")
      failBlock(error)
      
      // Make sure we break the reference cycles
      self.taskBlock = nil
      self.failBlock = nil
    }
  }
  
  // Just break the reference cycle. Assumption is that ARC will clean up the rest
  func success() {
    self.taskBlock = nil
    self.failBlock = nil
  }
  
  
  // Attempt retry as appropriate. Otherwise returns False.
//  func attemptRetryBasedOnHttpStatus(httpStatus: HTTPStatusCode, after delaySeconds: Double = 0, withQoS serviceLevel: DispatchQoS.QoSClass = .background) -> Bool {
//
//    switch httpStatus {
//
//    case .ok:
//      SLLog.assert("attemptRetryBasedOnHttpStatus() should only be used against non-good statuses")
//      return false  // Should never be here to begin with
//
//      // Add other explicity handlings here
//
//    // Explicit retry cases
//    case .gatewayTimeout, .requestTimeout, .iisLoginTimeout, .temporaryRedirect:
//      if !attempt(after: delaySeconds, withQoS: serviceLevel) {
//        SLLog.warning("Retry attempts exhausted. Final \(httpStatus.description)")
//        return false
//      }
//
//    default:
//      // Class based retry cases
//      if httpStatus.isInformational || httpStatus.isSuccess || httpStatus.isServerError {
//        if !attempt(after: delaySeconds, withQoS: serviceLevel) {
//          SLLog.warning("Retry attempts exhausted. Final \(httpStatus.description)")
//          return false
//        }
//      } else { // if httpStatus.isRedirection || httpStatus.isClientError {
//        SLLog.warning("Http Status failed. Retry not recommended - \(httpStatus.description)")
//        done()
//        return false
//      }
//    }
//    return true
//  }
//
//  // Attempt retry as appropriate. Otherwise returns False.
//  func attemptRetryBasedOnURLError(_ error: URLError, after delaySeconds: Double = 0, withQoS serviceLevel: DispatchQoS.QoSClass = .background) -> Bool {
//    switch error.code {
//    case .timedOut, .secureConnectionFailed, .requestBodyStreamExhausted, .notConnectedToInternet, .networkConnectionLost, .httpTooManyRedirects, .downloadDecodingFailedMidStream, .downloadDecodingFailedToComplete, .dnsLookupFailed, .cannotLoadFromNetwork, .cannotFindHost, .cannotConnectToHost, .badServerResponse, .backgroundSessionWasDisconnected, .backgroundSessionInUseByAnotherProcess:
//
//      if !attempt(after: delaySeconds, withQoS: serviceLevel) {
//        SLLog.warning("Retry attempts exhausted. Final URLError - \(error.localizedDescription)")
//        return false
//      }
//
//    default:
//      SLLog.warning("NSURLError. Retry not recommended - \(error.localizedDescription)")
//      return false
//    }
//    return true
//  }
}
