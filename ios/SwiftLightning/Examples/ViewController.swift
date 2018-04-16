//
//  ViewController.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-02.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit
import SwiftGRPC
import SwiftProtobuf

class ViewController: UIViewController {
  
  var walletUnlockerService: Lnrpc_WalletUnlockerServiceClient?
  var lightningService: Lnrpc_LightningServiceClient?
  var cipherSeedMnemonic: [String]?
  
  @IBOutlet var passwordField: UITextField!
  
  @IBAction func generateSeed(_ sender: UIButton) {
    
    prepareWalletUnlockerService()
    
    do {
      _ = try walletUnlockerService!.genSeed(Lnrpc_GenSeedRequest()) { (response, result) in
        if let response = response {
          var ciperSeedMnemonicDisplayString = "Generated Mnemonic: "
          self.cipherSeedMnemonic = response.cipherSeedMnemonic
          
          for mnemonicWord in response.cipherSeedMnemonic {
            ciperSeedMnemonicDisplayString += mnemonicWord
            ciperSeedMnemonicDisplayString += " "
          }
          SCLog.verbose(ciperSeedMnemonicDisplayString)

        } else {
          SCLog.warning("LND Gen Seed Failed - \(result)")
        }
      }
    } catch {

    }
  }
  
  
  @IBAction func createWallet(_ sender: UIButton) {
    
    guard let cipherSeedMnemonic = cipherSeedMnemonic else {
      SCLog.warning("No Cipher Seed Mnemonic")
      return
    }
    
    guard let passwordText = passwordField.text, let passwordData = passwordText.data(using: .utf8) else {
      SCLog.warning("No Wallet Password Entered")
      return
    }
    
    prepareWalletUnlockerService()
    
    var initWalletRequest = Lnrpc_InitWalletRequest()
    initWalletRequest.cipherSeedMnemonic = cipherSeedMnemonic
    initWalletRequest.walletPassword = passwordData  // TOOD: - Should provide password restriction
    
    do {
      _ = try walletUnlockerService!.initWallet(initWalletRequest) { (response, result) in
        if response != nil {
          SCLog.info("LND Init Wallet Success!")
        } else {
          SCLog.warning("LND Init Wallet Failed - \(result)")
        }
      }
    } catch {
      
    }
  }
  
  
  @IBAction func unlockWallet(_ sender: UIButton) {
    guard let passwordText = passwordField.text, let passwordData = passwordText.data(using: .utf8) else {
      SCLog.warning("No Wallet Password Entered")
      return
    }
    
    prepareWalletUnlockerService()
    
    var unlockWalletRequest = Lnrpc_UnlockWalletRequest()
    unlockWalletRequest.walletPassword = passwordData
    
    do {
      _ = try walletUnlockerService!.unlockWallet(unlockWalletRequest) { (response, result) in
        if response != nil {
          SCLog.info("LND Unlock Wallet Success!")
        } else {
          SCLog.warning("LND Unlock Wallet Failed - \(result)")
        }
      }
    } catch {
      
    }
  }
  
  
  @IBAction func getInfo(_ sender: UIButton) {
    prepareLightningService()
    
    do {
      _ = try lightningService!.getInfo(Lnrpc_GetInfoRequest()) { (response, result) in
        if let response = response {
          SCLog.verbose("")
          SCLog.verbose("Identity Pubkey:       \(response.identityPubkey)")
          SCLog.verbose("Alias:                 \(response.alias)")
          SCLog.verbose("Num Pending Channels:  \(response.numPendingChannels)")
          SCLog.verbose("Num Active Channels :  \(response.numActiveChannels)")
          SCLog.verbose("Number of Peers:       \(response.numPeers)")
          SCLog.verbose("Block Height:          \(response.blockHeight)")
          SCLog.verbose("Block Hash:            \(response.blockHash)")
          SCLog.verbose("Synced to Chain:       \(response.syncedToChain)")
          SCLog.verbose("Testnet:               \(response.testnet)")
          SCLog.verbose("Chains:                \(response.chains.joined(separator: ", "))")
          SCLog.verbose("URIs:                  \(response.uris.joined(separator: ", "))")
          SCLog.verbose("Best Header Timestamp: \(response.bestHeaderTimestamp)")
          
        } else {
          SCLog.warning("LND Get Info Failed - \(result)")
        }
      }
    } catch {
      
    }
  }
  
  
  private func prepareWalletUnlockerService() {
    if walletUnlockerService == nil {
      let tlsCertURL = URL(fileURLWithPath: LND.directoryPath).appendingPathComponent("tls.cert")
      let tlsCert = try! String(contentsOf: tlsCertURL)
      
      walletUnlockerService = Lnrpc_WalletUnlockerServiceClient(address: "localhost:\(LND.rpcListenPort)", certificates: tlsCert, host: nil)
    }
  }
  
  
  private func prepareLightningService() {
    if lightningService == nil {
      let tlsCertURL = URL(fileURLWithPath: LND.directoryPath).appendingPathComponent("tls.cert")
      let tlsCert = try! String(contentsOf: tlsCertURL)  // TODO: Error Handling
      
      let macaroonURL = URL(fileURLWithPath: LND.directoryPath).appendingPathComponent("admin.macaroon")
      let macaroonBinary = try! Data(contentsOf: macaroonURL)  // TODO: Error Handling
      let macaroonHexString = macaroonBinary.hexEncodedString()
      
      lightningService = Lnrpc_LightningServiceClient(address: "localhost:\(LND.rpcListenPort)", certificates: tlsCert, host: nil)
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
