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
    
    LightningdHelloWorld()
    LightningdStartDaemon()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

