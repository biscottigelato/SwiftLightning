//
//  SLUnboxedHeading.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-17.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class SLUnboxedHeading: NibView {

  @IBOutlet weak var logo: SLLogoView!
  @IBOutlet weak var title: UILabel!
  @IBOutlet weak var logoHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var stackView: UIStackView!
  
  @IBOutlet weak var headerButton: UIButton!
  
  override var intrinsicContentSize: CGSize {
    let logoHeight = logoHeightConstraint.constant
    let logoWidth = logoHeight
    
    var width: CGFloat
    var height: CGFloat
    
    if title.isHidden {
      width = logoWidth
      height = logoHeight
    } else {
      width = logoWidth + stackView.spacing + title.intrinsicContentSize.width
      height = max(logoHeight, title.intrinsicContentSize.height)
    }
    
    return CGSize(width: width, height: height)
  }
}
