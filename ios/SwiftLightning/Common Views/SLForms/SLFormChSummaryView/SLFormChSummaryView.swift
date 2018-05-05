//
//  SLFormChSummaryView.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-25.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class SLFormChSummaryView: NibView {
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var canPayAmtLabel: UILabel!
  @IBOutlet weak var canRcvAmtLabel: UILabel!
  @IBOutlet weak var feeAmtLabel: UILabel!
  @IBOutlet weak var feeStackView: UIStackView!
  
  @IBOutlet weak var topBottomStackHeight: NSLayoutConstraint!
  @IBOutlet weak var middleStackHeight: NSLayoutConstraint!
  
  
  @IBInspectable var titleText: String {
    get {
      return titleLabel.text ?? ""
    }
    set {
      titleLabel.text = newValue
    }
  }
  
  
  @IBInspectable var hideFeeStack: Int {
    get {
      return feeStackView.isHidden ? 1 : 0
    }
    set {
      if newValue == 1 {
        feeStackView.isHidden = true
      } else {
        feeStackView.isHidden = false
      }
      invalidateIntrinsicContentSize()
    }
  }
  
  
  override var intrinsicContentSize: CGSize {
    var heightMultiple: CGFloat = 2.0
    if feeStackView.isHidden {
      heightMultiple = 1.0
    }
    
    let intrinsicHeight = heightMultiple*topBottomStackHeight.constant + middleStackHeight.constant
    return CGSize(width: SLDesign.Constants.defaultUIElementWidth, height: intrinsicHeight)
  }
}
