//
//  SLFormNodeView.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-25.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class SLFormNodeView: NibView {

  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var nodePubKeyLabel: UILabel!
  @IBOutlet weak var aliasNameLabel: UILabel!
  @IBOutlet weak var ipAddressLabel: UILabel!
  @IBOutlet weak var portNumberLabel: UILabel!
  
  @IBOutlet weak var aliasStackView: UIStackView!
  @IBOutlet weak var singleLabelHeight: NSLayoutConstraint!
  
  
  @IBInspectable var titleText: String {
    get {
      return titleLabel.text ?? ""
    }
    set {
      titleLabel.text = newValue
    }
  }
  
  
  @IBInspectable var hideAliasStack: Int {
    get {
      return aliasStackView.isHidden ? 1 : 0
    }
    set {
      if newValue == 1 {
        aliasStackView.isHidden = true
      } else {
        aliasStackView.isHidden = false
      }
      invalidateIntrinsicContentSize()
    }
  }
  
  
  override var intrinsicContentSize: CGSize {
    var multiple: CGFloat = 4.0
    if aliasStackView.isHidden {
      multiple = 3.0
    }
    
    return CGSize(width: SLDesign.Constants.defaultUIElementWidth, height: multiple*singleLabelHeight.constant)
  }
}
