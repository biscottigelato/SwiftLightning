//
//  ViewController.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-02.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit
import Lightningd

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
    
    guard let appDataPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?.path else {
      fatalError("Cannot get Application Support Folder URL")
    }
    
    let lndArgs = "--bitcoin.active --bitcoin.testnet --debuglevel=debug --bitcoin.node=neutrino --neutrino.connect=faucet.lightning.community"
    
    LightningdStartLND(appDataPath, lndArgs)
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

