//
//  SLFormChSummaryView.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-25.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class SLFormChSummaryView: NibView {
  
  @IBOutlet weak var canPayAmtLabel: UILabel!
  @IBOutlet weak var canRcvAmtLabel: UILabel!
  @IBOutlet weak var feeAmtLabel: UILabel!
  
  @IBOutlet weak var topBottomStackHeight: NSLayoutConstraint!
  @IBOutlet weak var middleStackHeight: NSLayoutConstraint!
  
  
  override var intrinsicContentSize: CGSize {
    let intrinsicHeight = 2*topBottomStackHeight.constant + middleStackHeight.constant
    return CGSize(width: SLDesign.Constants.defaultUIElementWidth, height: intrinsicHeight)
  }
}
