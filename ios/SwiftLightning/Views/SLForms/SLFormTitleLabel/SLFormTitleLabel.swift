//
//  SLFormTitleLabel.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-25.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class SLFormTitleLabel: NibView {
  
  
  // MARK: IBOutlets
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var singleLabelHeight: NSLayoutConstraint!
  
  
  override var intrinsicContentSize: CGSize {
    return CGSize(width: SLDesign.Constants.defaultUIElementWidth, height: singleLabelHeight.constant)
  }
  
  
  // MARK: Field Title
  
  @IBInspectable var title: String {
    get {
      return titleLabel.text ?? ""
    }
    set {
      titleLabel.text = newValue
    }
  }
  
  @IBInspectable var fontSize: CGFloat {
    get {
      return titleLabel.font.pointSize
    }
    set {
      titleLabel.font = UIFont.regularFont(newValue)
    }
  }
}
