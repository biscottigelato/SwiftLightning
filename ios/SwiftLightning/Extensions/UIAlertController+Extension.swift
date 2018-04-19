//
//  UIAlertController+Extension.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-18.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

extension UIAlertController {
  func addAction(title: String?, style: UIAlertActionStyle, handler: ((UIAlertAction) -> Void)? = nil) -> UIAlertController {
    self.addAction(UIAlertAction(title: title, style: style, handler: handler))
    return self
  }
}
