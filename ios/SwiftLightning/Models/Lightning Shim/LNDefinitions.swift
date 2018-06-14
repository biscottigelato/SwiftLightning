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
  static let defaultLightningNodePort = 9735
  static let maxValidLightningPort = 65535
  static let minValidLightningPort = 1
  static let minChannelSize = Bitcoin(inSatoshi: 20000)
  static let maxAutoChannelSize = Bitcoin(inSatoshi: 16000000)
  static let maxAutoChannels = 20
  static let defaultRetryCount: Int = 5
  static let defaultRetryDelay: Double = 1
  static let defaultChannelOpTimeout: TimeInterval = 200  // seconds
  static let nodesThresholdForCfilterCompl: UInt = 30
  static let minNodesForLightningOperation: UInt = 500
}


enum BitcoinPaymentType {
  case onChain
  case lightning
}


enum BitcoinPubKeyHexPrefix: String {
  case uncompressed = "4"
  case compressed1 = "2"
  case compressed2 = "3"
}


enum OnChainAddressType : Int {
  case p2wkh = 0
  case np2wkh = 1
  case p2pkh = 2
}


enum OnChainConfirmSpeed {
  case economy
  case normal
  case urgent
  case custom(Bitcoin)
  
  var confBlocks: Int {
    switch self {
    case .economy:
      return 800
    case .normal:
      return 40
    case .urgent:
      return 2
    default:
      return 0
    }
  }
  
  var description: String {
    switch self {
    case .economy:
      return "Economy (1 - 3 days)"
    case .normal:
      return "Normal (1 - 4 hours)"
    case .urgent:
      return "Urgent (10 - 30 minutes)"
    case .custom:
      return "Custom"
    }
  }
}


// MARK: Ligning Entities

enum LNOpenChannelUpdateType {
  case pending
  case confirmation
  case opened
}

enum LNCloseChannelUpdateType {
  case pending
  case confirmation
  case closed
}

struct LNPeer: CustomStringConvertible {
  var pubKey: String
  var address: String
  var bytesSent: UInt
  var bytesRecv: UInt
  var satSent: Int
  var satRecv: Int
  var inbound: Bool
  var pingTime: Int
  
  var description: String {
    return """
    
    LN Peer details -
    pubKey:    \(pubKey)
    address:   \(address)
    bytesSent: \(bytesSent)
    bytesRecv: \(bytesRecv)
    satSent:   \(satSent)
    satRecv:   \(satRecv)
    inbound:   \(inbound)
    pingTime:  \(pingTime)
    """
  }
}


struct LNChannel: CustomStringConvertible {
  var isActive: Bool
  var remotePubKey: String
  var channelPoint: String
  var chanID: UInt
  var capacity: Int
  var localBalance: Int
  var remoteBalance: Int
  var commitFee: Int
  var commitWeight: Int
  var feePerKw: Int
  var unsettledBalance: Int
  var totalSatoshisSent: Int
  var totalSatoshisReceived: Int
  var numUpdates: UInt
  var pendingHTLCs: [LNHTLC]
  var csvDelay: UInt
  var isPrivate: Bool
  
  var description: String {
    var descriptiveString = """
    
    LN Channel details -
    active:           \(isActive)
    remotePubKey:     \(remotePubKey)
    channelPoint:     \(channelPoint)
    chanID:           \(chanID)
    capacity:         \(capacity)
    localBalance:     \(localBalance)
    remoteBalance:    \(remoteBalance)
    commitFee:        \(commitFee)
    commitWeight:     \(commitWeight)
    feePerKw:         \(feePerKw)
    unsettledBalance: \(unsettledBalance)
    satoshisSent:     \(totalSatoshisSent)
    satoshisReceived: \(totalSatoshisReceived)
    numUpdates:       \(numUpdates)
    csvDelay:         \(csvDelay)
    private:          \(isPrivate)
    """
    
    for (index, htlc) in pendingHTLCs.enumerated() {
      descriptiveString += "\nHTLC #\(index)\n\(htlc)"
    }
    return descriptiveString
  }
}


struct LNHTLC: CustomStringConvertible {
  var incoming: Bool
  var amount: Int
  var hashLock: Data
  var expirationHeight: UInt
  
  var description: String {
    return """
    HTLC details -
    incoming:         \(incoming)
    amount:           \(amount)
    hashLock:         \(hashLock)
    expirationHeight: \(expirationHeight)
    """
  }
}


struct LNPendingChannel: CustomStringConvertible {
  var remoteNodePub: String
  var channelPoint: String
  var capacity: Int
  var localBalance: Int
  var remoteBalance: Int
  
  var description: String {
    return """
    Pending Channel details -
    remoteNodePub: \(remoteNodePub)
    channelPoint: \(channelPoint)
    capacity: \(capacity)
    localBalance: \(localBalance)
    remoteBalance: \(remoteBalance)
    """
  }
}


struct LNPendingHTLC: CustomStringConvertible {
  var incoming: Bool
  var amount: Int
  var outpoint: String
  var maturityHeight: UInt
  var blocksTilMaturity: Int
  var stage: UInt

  var description: String {
    return """
    Pending HTLC details -
    incoming: \(incoming)
    amount: \(amount)
    outpoint: \(outpoint)
    maturityHeight: \(maturityHeight)
    blocksTilMaturity: \(blocksTilMaturity)
    stage: \(stage)
    """
  }
}

struct LNPendingOpenChannel: CustomStringConvertible {
  var channel: LNPendingChannel
  var confirmationHeight: UInt
  var commitFee: Int
  var commitWeight: Int
  var feePerKw: Int
  
  var description: String {
    return """
    
    Pending Open Channel details -
    \(channel)
    confirmationHeight: \(confirmationHeight)
    commitFee: \(commitFee)
    commitWeight: \(commitWeight)
    feePerKw: \(feePerKw)
    """
  }
}

struct LNPendingCloseChannel: CustomStringConvertible {
  var channel: LNPendingChannel
  var closingTxID: String
  
  var description: String {
    return """
    
    Pending Close Channel details -
    \(channel)
    closingTxID: \(closingTxID)
    """
  }
}

struct LNPendingForceCloseChannel: CustomStringConvertible {
  var channel: LNPendingChannel
  var closingTxID: String
  var limboBalance: Int
  var maturityHeight: UInt
  var blocksTilMaturity: Int
  var recoveredBalance: Int
  var pendingHTLCs: [LNPendingHTLC]
  
  var description: String {
    var descriptiveString = """
    
    Pending Force Close Channel details -
    \(channel)
    closingTxID:        \(closingTxID)
    limboBalance:       \(limboBalance)
    maturityHeight:     \(maturityHeight)
    blocksTilMaturity:  \(blocksTilMaturity)
    recoveredBalance:   \(recoveredBalance)
    """
    
    for (index, pendingHTLCs) in pendingHTLCs.enumerated() {
      descriptiveString += "\nHTLC #\(index)\n\(pendingHTLCs)"
    }
    return descriptiveString
  }
}

struct LNWaitingCloseChannel: CustomStringConvertible {
  var channel: LNPendingChannel
  var hasChannel: Bool
  var limboBalance: Int
  
  var description: String {
    return """
    
    Waiting Close Channel
    \(channel)
    hasChannel: \(hasChannel)
    limboBalance: \(limboBalance)
    """
  }
}

struct LNPayment {
  var paymentHash: String
  var value: Int
  var creationDate: Int
  var path: [String]
  var fee: Int
  var paymentPreimage: String
  
  var description: String {
    return """
    
    Lightning Payment detail -
    paymentHash: \(paymentHash)
    value: \(value)
    creationDate: \(creationDate)
    path: \(path.joined(separator: ", "))
    fee: \(fee)
    paymentPreimage: \(paymentPreimage)
    """
  }
}

struct BTCTransaction {
  var txHash: String
  var amount: Int
  var numConfirmations: Int
  var blockHash: String
  var blockHeight: Int
  var timeStamp: Int
  var totalFees: Int
  var destAddresses: [String]
  
  var description: String {
    return """
    
    Bitcoin Transaction detail -
    txHash: \(txHash)
    amount: \(amount)
    numConfirmations: \(numConfirmations)
    blockHash: \(blockHash)
    blockHeight: \(blockHeight)
    timeStamp: \(timeStamp)
    totalFees: \(totalFees)
    destAddresses: \(destAddresses)
    """
  }
}

struct LNDInfo: CustomStringConvertible {
  var identityPubkey: String
  var alias: String
  var numPendingChannels: UInt
  var numActiveChannels: UInt
  var numPeers: UInt
  var blockHeight: UInt
  var blockHash: String
  var syncedToChain: Bool
  var testnet: Bool
  var chains: [String]
  var uris: [String]
  var bestHeaderTimestamp: Int
  var version: String
  
  var description: String {
    return """
    
    LND Information -
    Identity Pubkey:       \(identityPubkey)
    Alias:                 \(alias)
    Num Pending Channels:  \(numPendingChannels)
    Num Active Channels :  \(numActiveChannels)
    Number of Peers:       \(numPeers)
    Block Height:          \(blockHeight)
    Block Hash:            \(blockHash)")
    Synced to Chain:       \(syncedToChain)
    Testnet:               \(testnet)
    Chains:                \(chains.joined(separator: ", "))
    URIs:                  \(uris.joined(separator: ", "))
    Best Header Timestamp: \(bestHeaderTimestamp)
    Version:               \(version)
    """
  }
}

struct LNDNetworkInfo: CustomStringConvertible {
  var graphDiameter: UInt
  var avgOutDegree: Double
  var maxOutDegree: UInt
  var numNodes: UInt
  var numChannels: UInt
  var totalNetworkCapacity: Int
  var avgChannelSize: Double
  var minChannelSize: Int
  var maxChannelSize: Int
  
  var description: String {
    return """
    
    LND Network Info -
    Graph Diameter:         \(graphDiameter)
    Avg Out Degree:         \(avgOutDegree)
    Max Out Degree:         \(maxOutDegree)
    Number of Nodes:        \(numNodes)
    Number of Channels:     \(numChannels)
    Total Network Capacity: \(totalNetworkCapacity)
    Avg Channel Size:       \(avgChannelSize)
    Min Channel Size:       \(minChannelSize)
    Max Channel Size:       \(maxChannelSize)
    """
  }
}

struct LNPayReq: CustomStringConvertible {
  var destination: String
  var paymentHash: String
  var numSatoshis: Int
  var timestamp: Int
  var expiry: Int
  var payDescription: String
  var descriptionHash: String
  var fallbackAddr: String
  var cltvExpiry: Int
  
  var description: String {
    return """
    
    LN Payment Request -
    Destination:      \(destination)
    Payment Hash:     \(paymentHash)
    Num Satoshis:     \(numSatoshis)
    Timestamp:        \(timestamp)
    Expiry:           \(expiry)
    Description:      \(payDescription)
    Description Hash: \(descriptionHash)
    Fallback Address: \(fallbackAddr)
    CLTV Expiry:      \(cltvExpiry)
    """
  }
}

struct LNRoute: CustomStringConvertible {
  var totalTimeLock: UInt
  var totalFees: Int
  var totalAmt: Int
  var hops: [LNHop]
  var totalFeesMsat: Int
  var totalAmtMsat: Int
  
  var description: String {
    var descriptiveString = """
    
    LN Route details -
    totalTimeLock: \(totalTimeLock)
    totalFees:     \(totalFees)
    totalAmt:      \(totalAmt)
    totalFeesMsat: \(totalFeesMsat)
    totalAmtMsat:  \(totalAmtMsat)
    """
    
    for (index, hop) in hops.enumerated() {
      descriptiveString += "\nHop #\(index)\n\(hop)"
    }
    return descriptiveString
  }
}

struct LNHop: CustomStringConvertible {
  var chanID: UInt
  var chanCapacity: Int
  var amtToForward: Int
  var fee: Int
  var expiry: UInt
  var amtToForwardMsat: Int
  var feeMsat: Int
  
  var description: String {
    return """
    Hop details -
    chanID:           \(chanID)
    chanCapacity:     \(chanCapacity)
    amtToForward:     \(amtToForward)
    expiry:           \(expiry)
    amtToForwardMsat: \(amtToForwardMsat)
    feeMsat:          \(feeMsat)
    """
  }
}

struct LNNode: CustomStringConvertible {
  var lastUpdate: UInt
  var pubKey: String
  var alias: String
  var network: [String]
  var address: [String]
  var color: String
  var numChannels: UInt
  var totalCapacity: Int
  
  var description: String {
    return """
    
    Lightning Node details -
    lastUpdate: \(lastUpdate)
    pubKey: \(pubKey)
    alias: \(alias)
    network: \(network.joined(separator: ", "))
    address: \(address.joined(separator: ", "))
    color: \(color)
    numChannels: \(numChannels)
    totalCapacity: \(totalCapacity)
    """
  }
}

enum LNGraphTopologyUpdate: CustomStringConvertible {
  case node(String)  // ID Key
  case channel(String)  // ChannelPoint
  case closedChannel(String)  // ChannelPoint
  
  var description: String {
    switch self {
    case .node(let idKey):
      return "Graph Topology Node Update - identityKey: \(idKey)"
      
    case .channel(let channelPoint):
      return "Graph Topology Channel Edge Update - channelPoint: \(channelPoint)"
      
    case .closedChannel(let channelPoint):
      return "Graph Topology Close Channel Update -  channelPoint: \(channelPoint)"
    }
  }
}

struct LNAutopilotConfig: CustomStringConvertible {
  var active: Bool
  var fundAllocation: Double
  var minChannelValue: Int  // in Satoshi
  var maxChannelValue: Int  // in Satoshi
  var maxNumChannels: Int
  
  var description: String {
    return """

    LN Autopilot configuration -
    Active:            \(active)
    Fund Allocation %: \(fundAllocation)
    Min Channel Value: \(minChannelValue)
    Max Channel Value: \(maxChannelValue)
    Max # of Channels: \(maxNumChannels)
    """
  }
}


// MARK: Errors

enum LNError: LocalizedError {
  
  case createWalletInvalidCipherSeed
  case createWalletInvalidPassword
  
  case unlockWalletInvalidPassword
  
  case openChannelStreamNoType
  case closeChannelStreamNoType
  
  case addressTypeUnsupported
  
  case openChannelTimeoutError
  case closeChannelTimeoutError
  
  case lndConfLNDCofRWError(String)
  
  var errorDescription: String? {
    switch self {
      
    case .createWalletInvalidCipherSeed:
      return NSLocalizedString("Cipher seed invalid when creating wallet", comment: "LNError Type")
    case .createWalletInvalidPassword:
      return NSLocalizedString("Password invalid when creating wallet", comment: "LNError Type")
      
    case .unlockWalletInvalidPassword:
      return NSLocalizedString("Password invalid when unlocking wallet", comment: "LNError Type")
      
    case .openChannelStreamNoType:
      return NSLocalizedString("OpenChannel Stream Call result has no type", comment: "LN Error Type")
    case .closeChannelStreamNoType:
      return NSLocalizedString("CloseChannel Stream Call result has no type", comment: "LN Error Type")

    case .addressTypeUnsupported:
      return NSLocalizedString("New address generation must be of Segwit types", comment: "LN Error Type")
      
    case .openChannelTimeoutError:
      return NSLocalizedString("Open Channel Request Timeout", comment: "Open Channel Timeout Error")
    case .closeChannelTimeoutError:
      return NSLocalizedString("Close Channel Request Timeout", comment: "Close Channel Timeout Error")
      
    case .lndConfLNDCofRWError(let errorString):
      return NSLocalizedString("Read/Write error from lnd.conf - \(errorString)", comment: "LND Conf Change Error")
    }
  }
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



