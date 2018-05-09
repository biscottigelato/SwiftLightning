//
//  SLIcon30Button.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-16.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit


@IBDesignable class SLIcon30Button: UIButton {
  
  // MARK: - Constants
  
  struct Constants {
    static let defaultImageEdgeInsets = UIEdgeInsets(top: 5.0, left: 5.0, bottom: 5.0, right: 5.0)
    static let defaultSize = CGSize(width: 40.0, height: 40.0)
  }
  
  
  // MARK: - Public Variables
  
  override var intrinsicContentSize: CGSize {
    return Constants.defaultSize
  }
  
  
  // MARK: - Private Variables
  
  
  // MARK: - IBOutlets
  
  
  // MARK: - IBActions
  
  
  // MARK: - IBInspectables
  
  
  // MARK: - Public Instance Functions
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    imageEdgeInsets = Constants.defaultImageEdgeInsets
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    imageEdgeInsets = Constants.defaultImageEdgeInsets
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    imageEdgeInsets = Constants.defaultImageEdgeInsets
    
  }
  
  
  // MARK: - Private Instance Functions
  
}
