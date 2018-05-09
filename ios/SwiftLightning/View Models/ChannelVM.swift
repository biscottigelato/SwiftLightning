//
//  ChannelVM.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-05-04.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

struct ChannelVM {
  enum State: Int {  // Order here determines default sort. Smaller the higher up the list
    case error = 0
    case pendingOpen
    case pendingForceClose
    case waitingClose
    case pendingClose
    case connected
    case disconnected
  }
  
  enum AddlInfo {
    case opened
    case pendingOpen(UInt)  // Confirmation Height
    case waitingClose
    case pendingClose(String)  // CloseTxID
    case forceClose(Int, String)  // BlocksTilMaturity, CloseTxID
  }
  
  var canPayAmt: String  // TODO: Ref Amount
  var canRcvAmt: String
  var capacity: Bitcoin
  var nodePubKey: String
  var channelPoint: String
  
  var state: State
  var statusText: String
  var statusColor: UIColor
  
  var addlInfo: AddlInfo?
  
  
  static func getFromLN(completion: @escaping (() throws -> ([ChannelVM])) -> Void) {
  
    // Get list of normal channels
    LNServices.listChannels { (listResponder) in
      do {
        let openedChannels = try listResponder()
        
        // Get list of pending channels
        LNServices.pendingChannels { (pendingResponder) in
          do {
            let pendings = try pendingResponder()
            
            var channels = [ChannelVM]()
            var state: ChannelVM.State
            var statusText: String
            var statusColor: UIColor
            
            for openedChannel in openedChannels {
              if openedChannel.isActive {
                state = .connected
                statusText = "Connected"
                statusColor = UIColor.medAquamarine
              } else {
                state = .disconnected
                statusText = "Disconnected"
                statusColor = UIColor.lightTextGray
              }
              
              let canPayAmt = Bitcoin(inSatoshi: openedChannel.localBalance)
              let canRcvAmt = Bitcoin(inSatoshi: openedChannel.remoteBalance)
              
              let channel = ChannelVM(canPayAmt: canPayAmt.formattedInSatoshis(),
                                            canRcvAmt: canRcvAmt.formattedInSatoshis(),
                                            capacity: Bitcoin(inSatoshi: openedChannel.capacity),
                                            nodePubKey: openedChannel.remotePubKey,
                                            channelPoint: openedChannel.channelPoint,
                                            state: state,
                                            statusText: statusText,
                                            statusColor: statusColor,
                                            addlInfo: nil)
              channels.append(channel)
            }
            
            for pendingOpenChannel in pendings.pendingOpen {
              statusText = "Pending Open"
              statusColor = UIColor.sandyOrange
              
              let canPayAmt = Bitcoin(inSatoshi: pendingOpenChannel.channel.localBalance)
              let canRcvAmt = Bitcoin(inSatoshi: pendingOpenChannel.channel.remoteBalance)
              let addlInfo = AddlInfo.pendingOpen(UInt(pendingOpenChannel.confirmationHeight))
              
              let channel = ChannelVM(canPayAmt: canPayAmt.formattedInSatoshis(),
                                            canRcvAmt: canRcvAmt.formattedInSatoshis(),
                                            capacity: Bitcoin(inSatoshi: pendingOpenChannel.channel.capacity),
                                            nodePubKey: pendingOpenChannel.channel.remoteNodePub,
                                            channelPoint: pendingOpenChannel.channel.channelPoint,
                                            state: ChannelVM.State.pendingOpen,
                                            statusText: statusText,
                                            statusColor: statusColor,
                                            addlInfo: addlInfo)
              channels.append(channel)
            }
            
            for pendingCloseChannel in pendings.pendingClose {
              statusText = "Pending Close"
              statusColor = UIColor.sandyOrange
              
              let canPayAmt = Bitcoin(inSatoshi: pendingCloseChannel.channel.localBalance)
              let canRcvAmt = Bitcoin(inSatoshi: pendingCloseChannel.channel.remoteBalance)
              let addlInfo = AddlInfo.pendingClose(pendingCloseChannel.closingTxID)
              
              let channel = ChannelVM(canPayAmt: canPayAmt.formattedInSatoshis(),
                                            canRcvAmt: canRcvAmt.formattedInSatoshis(),
                                            capacity: Bitcoin(inSatoshi: pendingCloseChannel.channel.capacity),
                                            nodePubKey: pendingCloseChannel.channel.remoteNodePub,
                                            channelPoint: pendingCloseChannel.channel.channelPoint,
                                            state: ChannelVM.State.pendingClose,
                                            statusText: statusText,
                                            statusColor: statusColor,
                                            addlInfo: addlInfo)
              channels.append(channel)
            }
            
            for pendingForceCloseChannel in pendings.pendingForceClose {
              statusText = "Pending Force Close"
              statusColor = UIColor.jellyBeanRed
              
              let canPayAmt = Bitcoin(inSatoshi: pendingForceCloseChannel.channel.localBalance)
              let canRcvAmt = Bitcoin(inSatoshi: pendingForceCloseChannel.channel.remoteBalance)
              let addlInfo = AddlInfo.forceClose(pendingForceCloseChannel.blocksTilMaturity,
                                                 pendingForceCloseChannel.closingTxID)
              
              let channel = ChannelVM(canPayAmt: canPayAmt.formattedInSatoshis(),
                                            canRcvAmt: canRcvAmt.formattedInSatoshis(),
                                            capacity: Bitcoin(inSatoshi: pendingForceCloseChannel.channel.capacity),
                                            nodePubKey: pendingForceCloseChannel.channel.remoteNodePub,
                                            channelPoint: pendingForceCloseChannel.channel.channelPoint,
                                            state: ChannelVM.State.pendingForceClose,
                                            statusText: statusText,
                                            statusColor: statusColor,
                                            addlInfo: addlInfo)
              channels.append(channel)
            }
            
            for waitingCloseChannel in pendings.waitingClose {
              statusText = "Waiting for Close"
              statusColor = UIColor.sandyOrange
              
              let canPayAmt = Bitcoin(inSatoshi: waitingCloseChannel.channel.localBalance)
              let canRcvAmt = Bitcoin(inSatoshi: waitingCloseChannel.channel.remoteBalance)
              
              let channel = ChannelVM(canPayAmt: canPayAmt.formattedInSatoshis(),
                                            canRcvAmt: canRcvAmt.formattedInSatoshis(),
                                            capacity: Bitcoin(inSatoshi: waitingCloseChannel.channel.capacity),
                                            nodePubKey: waitingCloseChannel.channel.remoteNodePub,
                                            channelPoint: waitingCloseChannel.channel.channelPoint,
                                            state: ChannelVM.State.waitingClose,
                                            statusText: statusText,
                                            statusColor: statusColor,
                                            addlInfo: nil)
              channels.append(channel)
            }
            
            completion({ return channels })
            
          } catch {
            completion({ throw error })
          }
        }  // LNServices.pendingChannels
        
      } catch {
        completion({ throw error })
      }
    }  // LNServices.listChannels
    
  }  // static func getFromLN(complettion:)
}
