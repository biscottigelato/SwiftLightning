//
//  SLFormScrollView.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-21.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit
import SnapKit


@IBDesignable class SLFormScrollView: UIScrollView {

  struct Constants {
    static let defaultCornerRadius: CGFloat = 20.0
    static let defaultLayoutMargin: CGFloat = 10.0 // SLBarButton.Constants.halfWidthLayoutMargin
  }

  override var intrinsicContentSize: CGSize {
    let screenSize = UIScreen.main.bounds.size
    return CGSize(width: screenSize.width - 2*Constants.defaultLayoutMargin, height: screenSize.height/2)
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    content
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    layer.cornerRadius = Constants.defaultCornerRadius
    backgroundColor = UIColor.formBackground
    shadowColor = UIColor.formShadow
  }
}
