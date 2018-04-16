//
//  LND.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-06.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation
import Lightningd

class LND {
  
  static var rpcListenPort: UInt = 10009
  static var peerListenPort: UInt = 9735
  static var restListenPort: UInt = 8080
  static var neutrinoAddress: String = "btcd0.lightning.computer:18333"
  static var directoryPath: String = ""
  static var lndQueue: DispatchQueue?
  
  static func initialize() {
    
    getenv("HOME")
    
    // Obtain the path to Application Support
    guard let appSupportPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.path else {
      fatalError("Cannot get Application Support Folder URL")
    }
    directoryPath = appSupportPath + "/lnd"
    
    // Arguments for LND Start
    var lndArgs = ""
    lndArgs += "--bitcoin.active"
    lndArgs += " "
    lndArgs += "--bitcoin.testnet"
    lndArgs += " "
    lndArgs += "--bitcoin.node=neutrino"
    lndArgs += " "
    lndArgs += "--neutrino.connect=\(neutrinoAddress)"
    lndArgs += " "
    lndArgs += "--rpclisten=localhost:\(rpcListenPort)"
    lndArgs += " "
    lndArgs += "--listen=localhost:\(peerListenPort)"
    lndArgs += " "
    lndArgs += "--restlisten=localhost:\(restListenPort)"
    lndArgs += " "
//    lndArgs += "--autopilot.active=1"
//    lngArgs += " "
//    lndArgs += "--no-macaroons"
//    lndArgs += " "
    
    #if DEBUG
    lndArgs += "--debuglevel=debug"
    #else
    lndArgs += "--debuglevel=info"
    #endif

    SCLog.verbose("LND Arguments: \(lndArgs)")
    
    // Start LND on it's own thread
    lndQueue = DispatchQueue(label: "LNDQueue", qos: .background, attributes: .concurrent)
    
    lndQueue!.async {
      LightningdStartLND(appSupportPath, lndArgs)
    }
  }
}
