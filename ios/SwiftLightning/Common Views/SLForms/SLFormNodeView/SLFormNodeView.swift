//
//  SLFormNodeView.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-25.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class SLFormNodeView: NibView {

  @IBOutlet weak var nodePubKeyLabel: UILabel!
  @IBOutlet weak var ipAddressLabel: UILabel!
  @IBOutlet weak var portNumberLabel: UILabel!
  
  @IBOutlet weak var singleLabelHeight: NSLayoutConstraint!
  
  override var intrinsicContentSize: CGSize {
    return CGSize(width: SLDesign.Constants.defaultUIElementWidth, height: 3*singleLabelHeight.constant)
  }
}
