//
//  SLSelectButton.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-06-11.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class SLSelectButton: UIButton {
  
  // MARK: - Constants
  
  struct Constants {
    static let defaultCornerRadius: CGFloat = SLDesign.Constants.defaultCornerRadius
    static let defaultHeight: CGFloat = 42.0
    static let defaultFontSize: CGFloat = 16.0
    static let defaultShadowOffset = CGSize(width: 0.0, height: 4.0)
    static let defaultShadowBlur: CGFloat = 5.0/2
    static let defaultShadowOpacity: Float = 0.3
    
    static let defaultFillAlpha: CGFloat = 0.75
    static let defaultBorderWidth: CGFloat = 1.0
    static let defaultSelectedColor = UIColor.medAquamarine
    static let defaultSelectedShadowColor = UIColor.medAquamarineShadow
    static let defaultSelectedTextColor = UIColor.normalText
    static let defaultDeselectedColor = UIColor.disabledGray
    static let defaultDeselectedShadowColor = UIColor.disabledGrayShadow
    static let defaultDeselectedTextColor = UIColor.disabledText
  }
  
  
  // MARK: - Public Variables
  #if !TARGET_INTERFACE_BUILDER
    var selectedColor = Constants.defaultSelectedColor
    var selectedShadowColor = Constants.defaultSelectedShadowColor
    var selectedTextColor = Constants.defaultSelectedTextColor
  #endif
  
  
  // MARK: - Public Instance Functions
  
  override func layoutSubviews() {
    super.layoutSubviews()

    layer.cornerRadius = Constants.defaultCornerRadius
    borderWidth = Constants.defaultBorderWidth
    titleLabel?.font = UIFont.regularFont(Constants.defaultFontSize)
    layer.shadowOffset = Constants.defaultShadowOffset
    layer.shadowRadius = Constants.defaultShadowBlur
    layer.shadowOpacity = Constants.defaultShadowOpacity
  }
  
  func selectedAppearance() {
    #if !TARGET_INTERFACE_BUILDER
      backgroundColor = selectedColor.withAlphaComponent(Constants.defaultFillAlpha)
      borderColor = selectedColor
      shadowColor = selectedShadowColor
      titleLabel?.textColor = selectedTextColor
    #endif
  }
  
  func deselectedAppearance() {
    #if !TARGET_INTERFACE_BUILDER
      backgroundColor = Constants.defaultDeselectedColor.withAlphaComponent(Constants.defaultFillAlpha/2)
      borderColor = Constants.defaultDeselectedColor
      shadowColor = Constants.defaultDeselectedShadowColor
      titleLabel?.textColor = UIColor.disabledText
    #endif
  }
}
