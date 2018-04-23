//
//  PlaygroundViewController.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-02.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit
import SwiftGRPC
import SwiftProtobuf

class PlaygroundViewController: UIViewController {
  
  var walletUnlockerService: Lnrpc_WalletUnlockerServiceClient?
  var lightningService: Lnrpc_LightningServiceClient?
  var cipherSeedMnemonic: [String]?
  
  @IBOutlet var passwordField: UITextField!
  
  @IBAction func generateSeed(_ sender: UIButton) {
    do {
      try LNServices.generateSeed() { (result) in
        do {
          let cipherSeed = try result()
          self.cipherSeedMnemonic = cipherSeed
        } catch {
          SLLog.warning(error.localizedDescription)
        }
      }
    } catch {
      SLLog.warning(error.localizedDescription)
    }
  }
  
  
  @IBAction func createWallet(_ sender: UIButton) {
    guard let cipherSeedMnemonic = cipherSeedMnemonic else {
      SLLog.warning("No Cipher Seed Mnemonic")
      return
    }
    
//    guard let passwordText = passwordField.text else {
//      SLLog.warning("No Wallet Password Entered")
//      return
//    }
    
    do {
      try LNServices.createWallet(walletPassword: "replaceme", cipherSeedMnemonic: cipherSeedMnemonic) { (result) in
        do {
          try result()
        } catch {
          SLLog.warning(error.localizedDescription)
        }
      }
    } catch {
      SLLog.warning(error.localizedDescription)
    }
  }
  
  
  @IBAction func unlockWallet(_ sender: UIButton) {
//    guard let passwordText = passwordField.text else {
//      SLLog.warning("No Wallet Password Entered")
//      return
//    }
    
    do {
      try LNServices.unlockWallet(walletPassword: "replaceme") { (result) in
        do {
          try result()
        } catch {
          SLLog.warning(error.localizedDescription)
        }
      }
    } catch {
      SLLog.warning(error.localizedDescription)
    }
  }
  
  
  @IBAction func getInfo(_ sender: UIButton) {
    LNServices.getInfo { (result) in
      do {
        try result()
      } catch {
        SLLog.warning(error.localizedDescription)
      }
    }
  }
  
  
  @IBAction func stopLND(_ sender: UIButton) {
    do {
      try LNServices.stopDaemon { (result) in
        do {
          try result()
        } catch {
          SLLog.warning(error.localizedDescription)
        }
      }
    } catch {
      SLLog.warning(error.localizedDescription)
    }
  }
  
  @IBAction func deleteLNDFiles(_ sender: UIButton) {
    do {
      let fileManager = FileManager.default
      let folderpath = LNServices.directoryPath
      let filePaths = try fileManager.contentsOfDirectory(atPath: folderpath)
      for filePath in filePaths {
        try fileManager.removeItem(atPath: folderpath + "/" + filePath)
      }
    } catch {
      SLLog.warning(error.localizedDescription)
    }
  }
  
  
  @IBAction func reinitLND(_ sender: UIButton) {
    LNServices.initialize()
  }
  
  
  private func prepareWalletUnlockerService() {
    if walletUnlockerService == nil {
      let tlsCertURL = URL(fileURLWithPath: LNServices.directoryPath).appendingPathComponent("tls.cert")
      let tlsCert = try! String(contentsOf: tlsCertURL)
      
      walletUnlockerService = Lnrpc_WalletUnlockerServiceClient(address: "localhost:\(LNServices.rpcListenPort)", certificates: tlsCert, host: nil)
    }
  }
  
  
  private func prepareLightningService() {
    if lightningService == nil {
      let tlsCertURL = URL(fileURLWithPath: LNServices.directoryPath).appendingPathComponent("tls.cert")
      let tlsCert = try! String(contentsOf: tlsCertURL)  // TODO: Error Handling
      
      let macaroonURL = URL(fileURLWithPath: LNServices.directoryPath).appendingPathComponent("admin.macaroon")
      let macaroonBinary = try! Data(contentsOf: macaroonURL)  // TODO: Error Handling
      let macaroonHexString = macaroonBinary.hexEncodedString()
      
      lightningService = Lnrpc_LightningServiceClient(address: "localhost:\(LNServices.rpcListenPort)", certificates: tlsCert, host: nil)
      lightningService!.metadata.add(key: "macaroon", value: macaroonHexString)
    }
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // For some reason GRPC Core have a very limited Cipher Suite set for SSL connections. This sets the environmental variable so
    // GRPC Core will expand the Cipher Suite set
    setenv("GRPC_SSL_CIPHER_SUITES", "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384", 1)
    
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}
