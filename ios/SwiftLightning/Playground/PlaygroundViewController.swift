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
    LNServices.newAddress { (response) in
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
                           streaming: openChannelStreaming,
                           completion: openChannelCompletion)
  }
  
  
  private func openChannelStreaming(response: () throws -> (Lnrpc_LightningOpenChannelCall)) {
    do {
      self.call = try response()
      try self.call!.receive(completion: self.callReceiveCallback)
    } catch {
      SLLog.warning("Open Channel Stream Call Failed - \(error.localizedDescription)")
    }
  }
  
  
  private func openChannelCompletion(response: () throws -> ()) {
    do {
      try response()
    } catch {
      SLLog.warning("Open Channel Result in Failure - \(error.localizedDescription)")
    }
  }
  
  
  @IBAction func receiveCall(_ sender: UIButton) {
    do {
      try self.call?.receive(completion: self.callReceiveCallback)
    } catch {
      SLLog.warning("Open Channel Receive Failed - \(error.localizedDescription)")
    }
  }
  
  
  private func callReceiveCallback(result: ResultOrRPCError<Lnrpc_OpenStatusUpdate?>) -> Void {
    SLLog.debug("LN Open Channel Stream Receive Response")
    
    switch result {
    case .result(let resultType):
      guard let update = resultType?.update else {
        SLLog.warning("LN Open Channel call stream result with no type")
        return
      }
  
      switch update {
      case .chanPending(let pendingUpdate):
        SLLog.info("LN Open Channel Pending Update:")
        
        SLLog.info(" TXID:          \(pendingUpdate.txid.hexEncodedString(options: .littleEndian))")
        SLLog.info(" Output Index:  \(pendingUpdate.outputIndex)")
      
      case .confirmation(let confirmUpdate):
        SLLog.info("LN Open Channel Confirmation Update:")
        
        SLLog.info(" Block SHA:          \(confirmUpdate.blockSha.hexEncodedString(options: .littleEndian))")
        SLLog.info(" Block Height:       \(confirmUpdate.blockHeight)")
        SLLog.info(" Num of Confs Left:  \(confirmUpdate.numConfsLeft)")
      
      case .chanOpen(let openUpdate):
        SLLog.info("LN Open Channel Open Update:")
        SLLog.info(" TXID:          \(openUpdate.channelPoint.fundingTxidStr)")
        SLLog.info(" Output Index:  \(openUpdate.channelPoint.outputIndex)")
      }
      
    case .error(let error):
      SLLog.warning("LN Open Channel call stream error - \(error.localizedDescription)")
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
