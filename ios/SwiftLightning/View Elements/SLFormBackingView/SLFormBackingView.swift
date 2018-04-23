//
//  SLFormScrollView.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-21.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit


@IBDesignable class SLFormBackingView: UIView {

  struct Constants {
    static let cornerRadius: CGFloat = SLDesignConstants.defaultCornerRadius
    static let layoutMargin: CGFloat = SLDesignConstants.formSidesMargin
    
    static let shadowOffset = CGSize(width: 0.0, height: 3.0)
    static let shadowBlur: CGFloat = 8.0/2
    static let shadowOpacity: Float = 0.38
  }

//  override var intrinsicContentSize: CGSize {
//    let screenSize = UIScreen.main.bounds.size
//    return CGSize(width: screenSize.width - 2*Constants.layoutMargin, height: screenSize.height/2)
//  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    layer.cornerRadius = Constants.cornerRadius
    clipsToBounds = true

//    backgroundColor = UIColor.formBackground
//    shadowColor = UIColor.formShadow
    layer.shadowOffset = Constants.shadowOffset
    layer.shadowRadius = Constants.shadowBlur
    layer.shadowOpacity = Constants.shadowOpacity
  }
}
