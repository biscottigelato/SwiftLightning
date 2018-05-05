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
    case pendingForceClose
    case pendingClose
    case pendingOpen
    case connected
    case disconnected
  }
  
  var canPayAmt: String  // TODO: Ref Amount
  var canRcvAmt: String
  var capacity: Bitcoin
  var nodePubKey: String
  var channelPoint: String
  var state: State
  var statusText: String
  var statusColor: UIColor
  var ipAddress: String?
  var port: String?
  var alias: String?
  var errMsg: String?
}
