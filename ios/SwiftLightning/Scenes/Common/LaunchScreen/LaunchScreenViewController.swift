//
//  LaunchScreenViewController.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-05-13.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

class LaunchScreenViewController: UIViewController {
  
  @IBOutlet weak var logoImageView: SLLogoView!
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidDisappear(animated)
//    logoImageView.animationDuration = TimeInterval(1.0)
//    logoImageView.pushAnimate()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
//    logoImageView.popAnimate()
  }
}
