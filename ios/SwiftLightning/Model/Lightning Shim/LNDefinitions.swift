//
//  LNDefinitions.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-17.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation
import grpc

struct LNConstants {
  static let cipherSeedMnemonicWordCount = 24
  static let walletPasswordMinLength = 6
}


enum OnChainConfirmSpeed {
  case economy
  case normal
  case urgent
  case custom(Bitcoin)
}


class GRPCResultError: NSError {
  static let domain = "GRPCResultDomain"
  
  override var localizedDescription: String {
    return userInfo["Message"] as! String
  }
  
  convenience init(code: Int, message: String) {
    self.init(domain: GRPCResultError.domain, code: code, userInfo: ["Message" : message])
  }
  
  struct StatusCode {
    static let oK = GRPC_STATUS_OK.rawValue
    
    /** The operation was cancelled (typically by the caller). */
    static let cancelled = GRPC_STATUS_CANCELLED.rawValue
    
    /** Unknown error.  An example of where this error may be returned is
     if a Status value received from another address space belongs to
     an error-space that is not known in this address space.  Also
     errors raised by APIs that do not return enough error information
     may be converted to this error. */
    static let unknown = GRPC_STATUS_UNKNOWN.rawValue
    
    /** Client specified an invalid argument.  Note that this differs
     from FAILED_PRECONDITION.  INVALID_ARGUMENT indicates arguments
     that are problematic regardless of the state of the system
     (e.g., a malformed file name). */
    static let invalidArgument = GRPC_STATUS_INVALID_ARGUMENT.rawValue
    
    /** Deadline expired before operation could complete.  For operations
     that change the state of the system, this error may be returned
     even if the operation has completed successfully.  For example, a
     successful response from a server could have been delayed long
     enough for the deadline to expire. */
    static let deadlineExceeded = GRPC_STATUS_DEADLINE_EXCEEDED.rawValue
    
    /** Some requested entity (e.g., file or directory) was not found. */
    static let notFound = GRPC_STATUS_NOT_FOUND.rawValue
    
    /** Some entity that we attempted to create (e.g., file or directory)
     already exists. */
    static let alreadyExists = GRPC_STATUS_ALREADY_EXISTS.rawValue
    
    /** The caller does not have permission to execute the specified
     operation.  PERMISSION_DENIED must not be used for rejections
     caused by exhausting some resource (use RESOURCE_EXHAUSTED
     instead for those errors).  PERMISSION_DENIED must not be
     used if the caller can not be identified (use UNAUTHENTICATED
     instead for those errors). */
    static let permissionDenied = GRPC_STATUS_PERMISSION_DENIED.rawValue
    
    /** The request does not have valid authentication credentials for the
     operation. */
    static let unauthenticated = GRPC_STATUS_UNAUTHENTICATED.rawValue
    
    /** Some resource has been exhausted, perhaps a per-user quota, or
     perhaps the entire file system is out of space. */
    static let resourceExhausted = GRPC_STATUS_RESOURCE_EXHAUSTED.rawValue
    
    /** Operation was rejected because the system is not in a state
     required for the operation's execution.  For example, directory
     to be deleted may be non-empty, an rmdir operation is applied to
     a non-directory, etc.
     
     A litmus test that may help a service implementor in deciding
     between FAILED_PRECONDITION, ABORTED, and UNAVAILABLE:
     (a) Use UNAVAILABLE if the client can retry just the failing call.
     (b) Use ABORTED if the client should retry at a higher-level
     (e.g., restarting a read-modify-write sequence).
     (c) Use FAILED_PRECONDITION if the client should not retry until
     the system state has been explicitly fixed.  E.g., if an "rmdir"
     fails because the directory is non-empty, FAILED_PRECONDITION
     should be returned since the client should not retry unless
     they have first fixed up the directory by deleting files from it.
     (d) Use FAILED_PRECONDITION if the client performs conditional
     REST Get/Update/Delete on a resource and the resource on the
     server does not match the condition. E.g., conflicting
     read-modify-write on the same resource. */
    static let failedPrecondition = GRPC_STATUS_FAILED_PRECONDITION.rawValue
    
    /** The operation was aborted, typically due to a concurrency issue
     like sequencer check failures, transaction aborts, etc.
     
     See litmus test above for deciding between FAILED_PRECONDITION,
     ABORTED, and UNAVAILABLE. */
    static let aborted = GRPC_STATUS_ABORTED.rawValue
    
    /** Operation was attempted past the valid range.  E.g., seeking or
     reading past end of file.
     
     Unlike INVALID_ARGUMENT, this error indicates a problem that may
     be fixed if the system state changes. For example, a 32-bit file
     system will generate INVALID_ARGUMENT if asked to read at an
     offset that is not in the range [0,2^32-1], but it will generate
     OUT_OF_RANGE if asked to read from an offset past the current
     file size.
     
     There is a fair bit of overlap between FAILED_PRECONDITION and
     OUT_OF_RANGE.  We recommend using OUT_OF_RANGE (the more specific
     error) when it applies so that callers who are iterating through
     a space can easily look for an OUT_OF_RANGE error to detect when
     they are done. */
    static let outOfRange = GRPC_STATUS_OUT_OF_RANGE.rawValue
    
    /** Operation is not implemented or not supported/enabled in this service. */
    static let unimplemented = GRPC_STATUS_UNIMPLEMENTED.rawValue
    
    /** Internal errors.  Means some invariants expected by underlying
     system has been broken.  If you see one of these errors,
     something is very broken. */
    static let internalErr = GRPC_STATUS_INTERNAL.rawValue
    
    /** The service is currently unavailable.  This is a most likely a
     transient condition and may be corrected by retrying with
     a backoff.
     
     WARNING: Although data MIGHT not have been transmitted when this
     status occurs, there is NOT A GUARANTEE that the server has not seen
     anything. So in general it is unsafe to retry on this status code
     if the call is non-idempotent.
     
     See litmus test above for deciding between FAILED_PRECONDITION,
     ABORTED, and UNAVAILABLE. */
    static let unavailable = GRPC_STATUS_UNAVAILABLE.rawValue
    
    /** Unrecoverable data loss or corruption. */
    static let dataLoss = GRPC_STATUS_DATA_LOSS.rawValue
    
    /** Force users to include a default branch: */
    // GRPC_STATUS__DO_NOT_USE = -1
  }
}


enum LNError: Int, Error {
  
  case createWalletInvalidCipherSeed
  case createWalletInvalidPassword
  
  case unlockWalletInvalidPassword
  
  
  // Computed Properties
  var code: Int { return self.rawValue }
  
  var localizedDescription: String {
    switch self {
      
    case .createWalletInvalidCipherSeed:
      return NSLocalizedString("Cipher seed invalid when creating wallet", comment: "LNError Type")
    case .createWalletInvalidPassword:
      return NSLocalizedString("Password invalid when creating wallet", comment: "LNError Type")
      
    case .unlockWalletInvalidPassword:
      return NSLocalizedString("Password invalid when unlocking wallet", comment: "LNError Type")
    }
  }
}
