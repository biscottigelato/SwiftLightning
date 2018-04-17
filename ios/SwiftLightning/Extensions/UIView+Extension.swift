//
//  DesignableViews.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-14.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

// This just exposes more attributes in Storyboards for even standard UIView based components
extension UIView {
  
  @IBInspectable var borderWidth: CGFloat {
    get {
      return layer.borderWidth
    }
    set {
      layer.borderWidth = newValue
    }
  }
  
  @IBInspectable var borderColor: UIColor? {
    get {
      if let color = layer.borderColor {
        return UIColor(cgColor: color)
      }
      return nil
    }
    set {
      if let color = newValue {
        layer.borderColor = color.cgColor
      } else {
        layer.borderColor = nil
      }
    }
  }
  
  @IBInspectable var shadowColor: UIColor? {
    get {
      if let color = layer.shadowColor {
        return UIColor(cgColor: color)
      }
      return nil
    }
    set {
      if let color = newValue {
        layer.shadowColor = color.cgColor
      } else {
        layer.shadowColor = nil
      }
    }
  }
}
