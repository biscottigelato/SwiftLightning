//
//  SLRandValues.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-19.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation

struct SLRandValues {
  static func get(_ numOfValues: UInt32, from startValue: UInt32, to endValue: UInt32) -> [UInt32] {
    
    let upperBound = endValue - startValue
    var picksRemaining = numOfValues
    var values = [UInt32]()
    
    while picksRemaining != 0 {
      let value = arc4random_uniform(upperBound+1) + startValue
      
      if !values.contains(value) {
        values.append(value)
        picksRemaining -= 1
      }
    }
    
    return values
  }
}
