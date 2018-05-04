//
//  GradientView.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-17.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class GradientView: UIView {
  let gradientLayer = CAGradientLayer()
  
  @IBInspectable var topGradientColor: UIColor? {
    didSet {
      setGradient(topGradientColor: topGradientColor, topPoint: topPoint,
                  middleGradientColor: middleGradientColor, middlePoint: middlePoint,
                  bottomGradientColor: bottomGradientColor, bottomPoint: bottomPoint)
    }
  }
  
  @IBInspectable var topPoint: Float {
    didSet {
      setGradient(topGradientColor: topGradientColor, topPoint: topPoint,
                  middleGradientColor: middleGradientColor, middlePoint: middlePoint,
                  bottomGradientColor: bottomGradientColor, bottomPoint: bottomPoint)
    }
  }
  
  @IBInspectable var middleGradientColor: UIColor? {
    didSet {
      setGradient(topGradientColor: topGradientColor, topPoint: topPoint,
                  middleGradientColor: middleGradientColor, middlePoint: middlePoint,
                  bottomGradientColor: bottomGradientColor, bottomPoint: bottomPoint)
    }
  }
  
  @IBInspectable var middlePoint: Float {
    didSet {
      setGradient(topGradientColor: topGradientColor, topPoint: topPoint,
                  middleGradientColor: middleGradientColor, middlePoint: middlePoint,
                  bottomGradientColor: bottomGradientColor, bottomPoint: bottomPoint)
    }
  }
  
  @IBInspectable var bottomGradientColor: UIColor? {
    didSet {
      setGradient(topGradientColor: topGradientColor, topPoint: topPoint,
                  middleGradientColor: middleGradientColor, middlePoint: middlePoint,
                  bottomGradientColor: bottomGradientColor, bottomPoint: bottomPoint)
    }
  }
  
  @IBInspectable var bottomPoint: Float {
    didSet {
      setGradient(topGradientColor: topGradientColor, topPoint: topPoint,
                  middleGradientColor: middleGradientColor, middlePoint: middlePoint,
                  bottomGradientColor: bottomGradientColor, bottomPoint: bottomPoint)
    }
  }
  
  
  // MARK: Initializers
  
  override init(frame: CGRect) {
    topPoint = 0.0
    middlePoint = 0.5
    bottomPoint = 1.0
    super.init(frame: frame)
  }
  
  required init?(coder aDecoder: NSCoder) {
    topPoint = 0.0
    middlePoint = 0.5
    bottomPoint = 1.0
    super.init(coder: aDecoder)
  }
  
  override func layoutSubviews() {
    setGradient(topGradientColor: topGradientColor, topPoint: topPoint,
                middleGradientColor: middleGradientColor, middlePoint: middlePoint,
                bottomGradientColor: bottomGradientColor, bottomPoint: bottomPoint)
  }
  
  
  // MARK: Private Instance Functions
  
  private func setGradient(topGradientColor: UIColor?, topPoint: Float = 0.0,
                           middleGradientColor: UIColor? = nil, middlePoint: Float = 0.5,
                           bottomGradientColor: UIColor?, bottomPoint: Float = 1.0) {
    
    if let topGradientColor = topGradientColor, let bottomGradientColor = bottomGradientColor {
      gradientLayer.frame = bounds
      gradientLayer.borderColor = layer.borderColor
      gradientLayer.borderWidth = layer.borderWidth
      gradientLayer.cornerRadius = layer.cornerRadius
      
      if let middleGradientColor = middleGradientColor {
        gradientLayer.colors = [topGradientColor.cgColor, middleGradientColor.cgColor, bottomGradientColor.cgColor]
        gradientLayer.locations = [topPoint as NSNumber, middlePoint as NSNumber, bottomPoint as NSNumber]
      } else {
        gradientLayer.colors = [topGradientColor.cgColor, bottomGradientColor.cgColor]
        gradientLayer.locations = [topPoint as NSNumber, bottomPoint as NSNumber]
      }
      layer.insertSublayer(gradientLayer, at: 0)
      
    } else {
      gradientLayer.removeFromSuperlayer()
    }
  }
}
