//
//  PlaygroundViewController.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-02.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit
import SwiftProtobuf

class PlaygroundViewController: SLViewController {
  
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
    
    do {
      try LNServices.createWallet(walletPassword: "qwertyui", cipherSeedMnemonic: cipherSeedMnemonic) { (result) in
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
    do {
      try LNServices.unlockWallet(walletPassword: "qwertyui") { (result) in
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
        _ = try result()
      } catch {
        SLLog.warning(error.localizedDescription)
      }
    }
  }
  
  
  @IBOutlet weak var totalBalanceLabel: UILabel!
  @IBOutlet weak var confirmedBalanceLabel: UILabel!
  @IBOutlet weak var unconfirmedBalanceLabel: UILabel!
  
  var totalBalance: Bitcoin = 0
  var confirmedBalance: Bitcoin = 0
  var unconfirmedBalance: Bitcoin = 0
  
  
  @IBAction func getBalance(_ sender: UIButton) {
    LNServices.walletBalance { (response) in
      do {
        let wallet = try response()
        
        DispatchQueue.main.async {
          self.totalBalance = Bitcoin(inSatoshi: wallet.total)
          self.confirmedBalance = Bitcoin(inSatoshi: wallet.confirmed)
          self.unconfirmedBalance = Bitcoin(inSatoshi: wallet.unconfirmed)
          
          self.totalBalanceLabel.text = "Total: \(self.totalBalance.formattedInSatoshis())"
          self.confirmedBalanceLabel.text = "Conf: \(self.confirmedBalance.formattedInSatoshis())"
          self.unconfirmedBalanceLabel.text = "Unconf: \(self.unconfirmedBalance.formattedInSatoshis())"
        }
        
      } catch {
        SLLog.warning(error.localizedDescription)
      }
    }
  }
  
  
  @IBAction func newAddress(_ sender: UIButton) {
    LNServices.newAddress(type: .np2wkh) { (response) in
      do {
        let newAddress = try response()
        SLLog.info("New Address: \(newAddress)")
      } catch {
        SLLog.warning("New Address error \(error.localizedDescription)")
      }
    }
  }
  
  
  @IBAction func connectPeer(_ sender: UIButton) {
    LNServices.connectPeer(pubKey: "020a3ce6e6893749bbcdb67ac67570e816a17c678bbcb6b12b0325f3fec036a014",
                           hostAddr: "189.4.126.1",
                           hostPort: LNConstants.defaultLightningNodePort) { (response) in
      do {
        try response()
      } catch {
        SLLog.warning(error.localizedDescription)
      }
    }
  }
  
  
  var call: Lnrpc_LightningOpenChannelCall?
  
  @IBAction func openChannel(_ sender: UIButton) {

    let nodePubKey = Data(hexString: "12345ce6e6893749bbcdb67ac67570e816a17c678bbcb6b12b0325f3fec036a014")!

    LNServices.openChannel(nodePubKey: nodePubKey,
                           localFundingAmt: Bitcoin(totalBalance/10).integerInSatoshis,
                           pushSat: 0,
                           targetConf: 1,
                           completion: openChannelCompletion)
  }
  
  
  private func openChannelCompletion(response: () throws -> (LNOpenChannelUpdateType)) {
    do {
      _ = try response()
    } catch {
      SLLog.warning("Open Channel Result in Failure - \(error.localizedDescription)")
    }
  }
  
  
  @IBAction func listPeer(_ sender: UIButton) {
    LNServices.listPeers { (response) in
      do {
        _ = try response()
      } catch {
        SLLog.warning(error.localizedDescription)
      }
    }
  }
  
  
  @IBAction func listChannels(_ sender: UIButton) {
    LNServices.listChannels { (response) in
      do {
        _ = try response()
      } catch {
        SLLog.warning(error.localizedDescription)
      }
    }
  }
  
  
  @IBAction func stopLND(_ sender: UIButton) {
//    LNServices.stopDaemon { (response) in
//      do {
//        _ = try response()
//      } catch {
//        SLLog.warning(error.localizedDescription)
//      }
//    }
    
    UIApplication.shared.delegate?.applicationWillTerminate?(UIApplication.shared)
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
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3.0) {
      try! LNServices.unlockWallet(walletPassword: "qwertyui") { _ in }
    }
//    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 120.0) {
//      LNServices.stopDaemon { _ in }
//    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}
