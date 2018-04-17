//
//  SLButtonView.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-16.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit
import SnapKit

@IBDesignable
class SLButtonView: UIButton {
  
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
    static let defaultHeight: CGFloat = 45.0
    static let defaultFontSize: CGFloat = 16.0
    
    static let smallSizedCornerRadius: CGFloat = 5.0
    static let smallSizedHeight: CGFloat = 28.0
    static let smallSizedFontSize: CGFloat = 12.0
  }
  
  
  // MARK: - Public Variables
  
  var slButtonSize: SizeType = .full
  
  
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
  
  override func awakeFromNib() {
    super.awakeFromNib()
    initButton(by: slButtonSize)
  }
  
  
  // MARK: - Private Instance Functions
  
  private func initButton(by sizeType: SizeType) {
  
    switch sizeType {
    case .full:
      layer.cornerRadius = Constants.defaultCornerRadius
      self.snp.makeConstraints { (make) -> Void in
        make.height.equalTo(Constants.defaultHeight)
        // make.center.equalTo(UIWindow.) Default autolayout against parent? If not, at least against the UIWindow?
      }
      
    case .half:
      layer.cornerRadius = Constants.defaultCornerRadius
      
    case .formFull:
      layer.cornerRadius = Constants.defaultCornerRadius
      
    case .formHalf:
      layer.cornerRadius = Constants.defaultCornerRadius
      
    case .field:
      layer.cornerRadius = Constants.smallSizedCornerRadius
    }
  }
}
