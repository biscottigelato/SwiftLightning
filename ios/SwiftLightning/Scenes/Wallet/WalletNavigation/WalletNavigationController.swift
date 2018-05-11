//
//  WalletNavigationController
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-22.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

class WalletNavigationController: UINavigationController {
  
  struct Constants {
    static let headerFont = UIFont.MontserratLight(18.0)  // Make font a touch smaller than during setup
    static let logoHeight: CGFloat = 30.0  // Make logo height a touch smaller than during setup
    static let logoAnimationDuration = TimeInterval(3.0)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Remove shadow under the Nav Bar
    navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
    navigationBar.shadowImage = UIImage()
    
    // Set this as a background color for the Nav Controller
    view.backgroundColor = UIColor.spaceCadetBlue
    
    // NavigationBar Title View - assume 'Syncing' to start
    let animationImages = [UIImage(named: "LightningLogo0")!,
                           UIImage(named: "LightningLogo1")!,
                           UIImage(named: "LightningLogo2")!,
                           UIImage(named: "LightningLogo3")!,
                           UIImage(named: "LightningLogo4")!]
    
    let headingView = SLUnboxedHeading()
    headingView.logoHeightConstraint.constant = Constants.logoHeight
    headingView.logo.animationImages = animationImages
    headingView.logo.animationDuration = Constants.logoAnimationDuration
    headingView.logo.startAnimating()
    
    headingView.title.isHidden = false
    headingView.title.font = Constants.headerFont
    headingView.title.text = "Syncing...  "  // add 2 spaces after to center
    
    navigationBar.addSubview(headingView)
    headingView.snp.makeConstraints { (make) in
      make.center.equalTo(self.navigationBar)
    }
    
    let percentageFormatter = NumberFormatter()
    percentageFormatter.numberStyle = .percent
    percentageFormatter.maximumFractionDigits = 0
    
    // Keep the header view updated to sync progress
    EventCentral.shared.regsiterSyncProgress { (synced, percentage, date) in
      DispatchQueue.main.async {
        if synced {
          headingView.logo.stopAnimating()
          headingView.logo.image = UIImage(named: "LightningLogo4")
          headingView.title.isHidden = true
        } else {
          if headingView.logo.isAnimating {
            headingView.logo.startAnimating()
          }
          headingView.title.isHidden = false
          headingView.title.text = "Syncing...  "  // add 2 spaces after to center
          
          if let percentText = percentageFormatter.string(from: NSNumber(value: percentage)) {
            headingView.title.text = "Sync - \(percentText)   "  // add 3 spaces after to center
          }
        }
      }
    }
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}
