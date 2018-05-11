//
//  CGPoint+Extension.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2017-11-06.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import CoreGraphics

extension CGPoint {
  func multiplyScalar(_ scalar: CGFloat) -> CGPoint {
    return CGPoint(x: scalar * self.x , y: scalar * self.y)
  }
}
