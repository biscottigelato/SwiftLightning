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
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Remove shadow under the Nav Bar
    navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
    navigationBar.shadowImage = UIImage()
    
    // Set this as a background color for the Nav Controller
    view.backgroundColor = UIColor.spaceCadetBlue
    
    let headingView = SLUnboxedHeading()
    headingView.logoHeightConstraint.constant = Constants.logoHeight
    
    headingView.title.isHidden = false
    headingView.title.font = Constants.headerFont
    headingView.title.text = "Syncing...  "  // add 2 spaces after to center
    
    navigationBar.addSubview(headingView)
    headingView.snp.makeConstraints { (make) in
      make.center.equalTo(self.navigationBar)
    }
    
    let percentageFormatter = NumberFormatter()
    percentageFormatter.numberStyle = .percent
    percentageFormatter.roundingMode = .down
    percentageFormatter.maximumFractionDigits = 0
    
    // Keep the header view updated to sync progress
    _ = EventCentral.shared.subscribeToSync { (synced, percentage, networked, nodes, date) in
      DispatchQueue.main.async {
        if synced && networked {
          headingView.logo.popAnimate()
          headingView.title.isHidden = true
          
        }
        // TODO: Once LND v0.5 fixes getting compact filters, Re-enable display for Getting Filters/Discovering Nodes
        else if synced {
          if !headingView.logo.isAnimating {
            headingView.logo.pushAnimate()
          }
          headingView.title.isHidden =  false
          if nodes < LNConstants.nodesThresholdForCfilterCompl {
            headingView.title.text = "Getting Filters... "  // add 1 space after to center
          } else {
            headingView.title.text = "\(nodes) Nodes found  "  // add 2 spaces after to center
          }
        }
        else {
          if !headingView.logo.isAnimating {
            headingView.logo.pushAnimate()
          }
          headingView.title.isHidden = false
          headingView.title.text = "Syncing...  "  // add 2 spaces after to center
          
          if let percentText = percentageFormatter.string(from: NSNumber(value: percentage)) {
            headingView.title.text = "Sync - \(percentText)   "  // add 3 spaces after to center
          }
        }
        headingView.invalidateIntrinsicContentSize()
        headingView.layoutIfNeeded()
      }
    }
    
    // Register an action to the Heading View gesture recognizer
    headingView.headerButton.addTarget(self, action: #selector(headerTapped(_:)), for: .touchUpInside)
  }
  
  
  // MARK: Wallet Info Tapped
  @objc private func headerTapped(_ sender: UIButton) {
    
    // Prevent WalletInfo recursion
    if let topViewController = topViewController, topViewController is WalletInfoViewController {
      return
    }
    
    // Screw Routers...
    let storyboard = UIStoryboard(name: "WalletInfo", bundle: nil)
    let destinationVC = storyboard.instantiateViewController(withIdentifier: "WalletInfoViewController") as! WalletInfoViewController
    // var destinationDS = destinationVC.router!.dataStore!
    
    // Force the top VC in the navigation stack to present the WalletInfo view
    destinationVC.setPopTransition(dismissIsInteractive: true)
    delegate = destinationVC
    pushViewController(destinationVC, animated: true)
  }
}
