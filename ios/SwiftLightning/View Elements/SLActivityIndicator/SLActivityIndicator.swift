//
//  SLActivityIndicator.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-21.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class SLActivityIndicator: NibView {

  override func layoutSubviews() {
    super.layoutSubviews()
    
    layer.cornerRadius = 15.0
    layer.masksToBounds = true
  }
  
  override var intrinsicContentSize: CGSize {
    return CGSize(width: 80.0, height: 80.0)
  }
}
