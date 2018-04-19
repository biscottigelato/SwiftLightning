//
//  URL+Extension.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-18.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation

extension URL {
  
  static func addHttpIfNeeded(to linkText: String) -> String {
    var validHttpText = linkText
    let lowercaseText = linkText.lowercased()
    
    if !lowercaseText.hasPrefix("http://") && !lowercaseText.hasPrefix("https://") {
      validHttpText = "http://" + linkText
    }
    return validHttpText
  }
}
