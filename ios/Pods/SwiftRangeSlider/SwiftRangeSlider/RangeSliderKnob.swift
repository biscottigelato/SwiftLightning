//
//  RangeSliderKnobLayer.swift
//  SwiftRangeSlider
//
//  Created by Brian Corbin on 5/22/16.
//  Copyright © 2016 Caramel Apps. All rights reserved.
//

import UIKit
import QuartzCore

enum Knob {
  case Neither
  case Lower
  case Upper
  case Both
}

public enum KnobAnchorPosition {
  case inside
  case center
}

class RangeSliderKnob: CALayer {
  static var KnobDelta: CGFloat = 2.0
    
  var highlighted: Bool = false {
    didSet {
      if let superLayer = superlayer, highlighted {
        removeFromSuperlayer()
        superLayer.addSublayer(self)
      }
      setNeedsDisplay()
    }
  }
  weak var rangeSlider: RangeSlider?
  
  override func draw(in ctx: CGContext) {
    if let slider = rangeSlider {
      let knobFrame = bounds.insetBy(dx: RangeSliderKnob.KnobDelta, dy: RangeSliderKnob.KnobDelta)
      let cornerRadius = knobFrame.height * slider.curvaceousness / 2
      let knobPath = UIBezierPath(roundedRect: knobFrame, cornerRadius: cornerRadius)
      
      let shadowColor = UIColor.gray
      if (rangeSlider!.knobHasShadow){
        ctx.setShadow(offset: CGSize(width: 0.0, height: 1.0), blur: 1.0, color: shadowColor.cgColor)
      }
      ctx.setFillColor(slider.knobTintColor.cgColor)
      ctx.addPath(knobPath.cgPath)
      ctx.fillPath()
      
      ctx.setStrokeColor(slider.knobBorderTintColor.cgColor)
      ctx.setLineWidth((rangeSlider?.knobBorderThickness)!)
      ctx.addPath(knobPath.cgPath)
      ctx.strokePath()
      
      if highlighted {
        ctx.setFillColor(UIColor(white: 0.0, alpha: 0.1).cgColor)
        ctx.addPath(knobPath.cgPath)
        ctx.fillPath()
      }
    }
  }
}
