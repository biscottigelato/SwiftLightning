//
//  WalletPageView.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-05-03.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class WalletPageView: NibView {

  @IBOutlet weak var txnHdrButton: UIButton!
  @IBOutlet weak var chHdrButton: UIButton!
  
  @IBOutlet weak var tableView: UITableView!
  
  @IBOutlet weak var leftButton: SLBarButton!
  @IBOutlet weak var rightButton: SLBarButton!
  
  
  enum PageType: Int {
    case transactions = 0
    case channels
  }
  
  var pageType: PageType = PageType.transactions
  
  @IBInspectable var pageTypeIndex: Int {
    get {
      return pageType.rawValue
    }
    set {
      pageType = PageType(rawValue: newValue) ?? .transactions
      initPageView(by: pageType)
    }
  }
  
  
  override func layoutSubviews() {
    initPageView(by: pageType)
  }
  
  
  private func initPageView(by pageType: PageType) {
    
    switch pageType {
    case .transactions:
      txnHdrButton.isEnabled = false
      txnHdrButton.titleLabel?.font = UIFont.semiBoldFont(13.0)
      chHdrButton.isEnabled = true
      chHdrButton.titleLabel?.font = UIFont.regularFont(13.0)
      
      leftButton.setTitle("Pay", for: .normal)
      rightButton.setTitle("Receive", for: .normal)
      
      #if !TARGET_INTERFACE_BUILDER
        leftButton.backgroundColor = UIColor.lightAzureBlue
        leftButton.shadowColor = UIColor.lightAzureBlueShadow
        rightButton.backgroundColor = UIColor.medAquamarine
        rightButton.shadowColor = UIColor.medAquamarineShadow
      #endif
      
    case .channels:
      txnHdrButton.isEnabled = true
      txnHdrButton.titleLabel?.font = UIFont.regularFont(13.0)
      chHdrButton.isEnabled = false
      chHdrButton.titleLabel?.font = UIFont.semiBoldFont(13.0)
      
      leftButton.setTitle("Manual Open", for: .normal)
      rightButton.setTitle("Autopilot", for: .normal)
      
      #if !TARGET_INTERFACE_BUILDER
        leftButton.backgroundColor = UIColor.lightAzureBlue
        leftButton.shadowColor = UIColor.lightAzureBlueShadow
        rightButton.backgroundColor = UIColor.sandyOrange
        rightButton.shadowColor = UIColor.sandyOrangeShadow
      #endif
      
    }
  }
}
