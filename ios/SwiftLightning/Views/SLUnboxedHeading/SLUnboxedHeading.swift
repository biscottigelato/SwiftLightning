//
//  SLUnboxedHeading.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-17.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class SLUnboxedHeading: NibView {

  @IBOutlet weak var logo: UIImageView!
  @IBOutlet weak var title: UILabel!
  @IBOutlet weak var logoHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var stackView: UIStackView!
  
  override var intrinsicContentSize: CGSize {
    let logoHeight = logoHeightConstraint.constant

    let width = stackView.intrinsicContentSize.width
    let height = max(logoHeight, stackView.intrinsicContentSize.height)
    
    return CGSize(width: width, height: height)
  }
}
