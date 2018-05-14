//
//  SLLineView.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-05-13.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class SLLineView: NibView {

  override var intrinsicContentSize: CGSize {
    return CGSize(width: SLDesign.Constants.defaultUIElementWidth, height: 1.0)
  }
}
