//
//  UITextField+Extension.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-17.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

extension UITextField {
  
  func togglePasswordVisibility() {
    isSecureTextEntry = !isSecureTextEntry
    
    if let existingText = text, isSecureTextEntry {
      /* When toggling to secure text, all text will be purged if the user
       * continues typing unless we intervene. This is prevented by first
       * deleting the existing text and then recovering the original text. */
      deleteBackward()
      
      if let textRange = textRange(from: beginningOfDocument, to: endOfDocument) {
        replace(textRange, withText: existingText)
      }
    }
  }
}
