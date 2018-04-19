//
//  SLBarButton.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-16.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit


@IBDesignable class SLBarButton: UIButton {
  
  // MARK: - Types & Enumerations
  
  enum SizeType: Int {  // Controls default height, font & width
    case full = 0
    case half
    case formFull
    case formHalf
    case field
  }
  
  
  // MARK: - Constants
  
  struct Constants {
    static let defaultCornerRadius: CGFloat = 10.0
    static let defaultHeight: CGFloat = 42.0
    static let defaultFontSize: CGFloat = 16.0
    static let defaultFontWeight = UIFont.Weight.regular
    static let defaultShadowOffset = CGSize(width: 0.0, height: 3.0)
    static let defaultShadowBlur: CGFloat = 4.0/2
    static let defaultShadowOpacity: Float = 0.3
    
    static let smallSizedCornerRadius: CGFloat = 5.0
    static let smallSizedWidth: CGFloat = 60.0
    static let smallSizedHeight: CGFloat = 28.0
    static let smallSizedFontSize: CGFloat = 12.0
    static let smallSizedFontWeight = UIFont.Weight.regular
    static let smallSizedShadowOffset = CGSize(width: 0.0, height: 1.0)
    static let smallSizedShadowBlur: CGFloat = 3.0/2
    static let smallSizedShadowOpacity: Float = 0.2
    
    static let defaultLayoutMargin: CGFloat = 16.0
  }
  
  
  // MARK: - Public Variables
  
  var intrinsicSize: CGSize = CGSize.zero
  var slButtonSize: SizeType = .full
  
  
  // MARK: - Private Variables
  
  
  // MARK: - IBOutlets
  
  
  // MARK: - IBActions
  
  
  // MARK: - IBInspectables
  
  @IBInspectable var sizeIndex: Int {
    get {
      return slButtonSize.rawValue
    }
    
    set {
      slButtonSize = SizeType(rawValue: newValue) ?? .full
      initButton(by: slButtonSize)
    }
  }
  
  
  // MARK: - Public Instance Functions
  
  override func layoutSubviews() {
    super.layoutSubviews()
    initButton(by: slButtonSize)
  }
  
  
  override var intrinsicContentSize: CGSize {
    SLLog.verbose("Intrinsic Size: \(intrinsicSize)")
    return intrinsicSize
  }
  
  
  // MARK: - Private Instance Functions
  
  private func initButton(by sizeType: SizeType) {
  
    // Pre-calculate the Intrinsic Size of the button
    
    let leftMargin = Constants.defaultLayoutMargin
    let rightMargin = Constants.defaultLayoutMargin
    var superviewWidth = UIScreen.main.bounds.width
    SLLog.verbose("Screen width \(superviewWidth)")
    
//    if let layoutMargins = superview?.layoutMargins {
//      if layoutMargins.left != 0 { leftMargin = layoutMargins.left }
//      if layoutMargins.right != 0 { rightMargin = layoutMargins.right }
//    }
//    else if let layoutMargins = UIScreen.main.focusedView?.layoutMargins {
//      if layoutMargins.left != 0 { leftMargin = layoutMargins.left }
//      if layoutMargins.right != 0 { rightMargin = layoutMargins.right }
//    }
    
    if let width = superview?.bounds.width {
      superviewWidth = width
      SLLog.verbose("Superview width \(superviewWidth)")
    }
    else if let width = window?.bounds.width {
      superviewWidth = width
      SLLog.verbose("Window width \(superviewWidth)")
    }
    
    switch sizeType {
    case .full:
      let buttonWidth = superviewWidth - leftMargin - rightMargin
      intrinsicSize = CGSize(width: buttonWidth, height: Constants.defaultHeight)
      layer.cornerRadius = Constants.defaultCornerRadius
      titleLabel?.font = UIFont.systemFont(ofSize: Constants.defaultFontSize, weight: Constants.defaultFontWeight)
      layer.shadowOffset = Constants.defaultShadowOffset
      layer.shadowRadius = Constants.defaultShadowBlur
      layer.shadowOpacity = Constants.defaultShadowOpacity
      
    case .half:
      let buttonWidth = (superviewWidth - 1.5*(leftMargin + rightMargin))/2
      intrinsicSize = CGSize(width: buttonWidth, height: Constants.defaultHeight)
      layer.cornerRadius = Constants.defaultCornerRadius
      titleLabel?.font = UIFont.systemFont(ofSize: Constants.defaultFontSize, weight: Constants.defaultFontWeight)
      layer.shadowOffset = Constants.defaultShadowOffset
      layer.shadowRadius = Constants.defaultShadowBlur
      layer.shadowOpacity = Constants.defaultShadowOpacity
      
    case .formFull:
      let buttonWidth = superviewWidth - leftMargin - rightMargin
      intrinsicSize = CGSize(width: buttonWidth, height: Constants.defaultHeight)
      layer.cornerRadius = Constants.defaultCornerRadius
      titleLabel?.font = UIFont.systemFont(ofSize: Constants.defaultFontSize, weight: Constants.defaultFontWeight)
      layer.shadowOffset = Constants.defaultShadowOffset
      layer.shadowRadius = Constants.defaultShadowBlur
      layer.shadowOpacity = Constants.defaultShadowOpacity
      
    case .formHalf:
      let buttonWidth = (superviewWidth - 1.5*(leftMargin + rightMargin))/2
      intrinsicSize = CGSize(width: buttonWidth, height: Constants.defaultHeight)
      layer.cornerRadius = Constants.defaultCornerRadius
      titleLabel?.font = UIFont.systemFont(ofSize: Constants.defaultFontSize, weight: Constants.defaultFontWeight)
      layer.shadowOffset = Constants.defaultShadowOffset
      layer.shadowRadius = Constants.defaultShadowBlur
      layer.shadowOpacity = Constants.defaultShadowOpacity
      
    case .field:
      intrinsicSize = CGSize(width: Constants.smallSizedWidth, height: Constants.smallSizedHeight)
      layer.cornerRadius = Constants.smallSizedCornerRadius
      titleLabel?.font = UIFont.systemFont(ofSize: Constants.defaultFontSize, weight: Constants.defaultFontWeight)
      layer.shadowOffset = Constants.smallSizedShadowOffset
      layer.shadowRadius = Constants.smallSizedShadowBlur
      layer.shadowOpacity = Constants.smallSizedShadowOpacity
    }

    invalidateIntrinsicContentSize()
  }
}
