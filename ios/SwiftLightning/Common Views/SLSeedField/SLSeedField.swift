//
//  SLSeedField.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-19.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class SLSeedField: NibView {
  
  @IBOutlet weak var textField: UITextField!
  @IBOutlet weak var numberLabel: UILabel!
  @IBOutlet weak var checkLabel: UILabel!
  
  @IBOutlet weak var fieldLineConstraint: NSLayoutConstraint!
  @IBOutlet weak var underlineHeightConstraint: NSLayoutConstraint!
  
  override var intrinsicContentSize: CGSize {
    let height = textField.intrinsicContentSize.height +
      fieldLineConstraint.constant +
      underlineHeightConstraint.constant
    
    return CGSize(width: 240.0, height: height)
  }
}
