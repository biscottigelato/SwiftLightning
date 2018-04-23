//
//  SLFormHeaderView.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-22.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class SLFormHeaderView: NibView {

  override var intrinsicContentSize: CGSize {
//    let screenSize = UIScreen.main.bounds.size
    return CGSize(width: 350, height: 40.0)
  }
  
  
  // MARK: Label
  
  @IBOutlet weak var headerLabel: UILabel!
  
  @IBInspectable var headerTitle: String {
    get {
      return headerLabel.text ?? ""
    }
    
    set {
      headerLabel.text = newValue
    }
  }
  
  
  // MARK: Icon
  
  enum IconType: Int {
    case bolt = 0
    case chain
  }
  
  var iconType: IconType = .bolt
  
  @IBOutlet weak var iconImageView: UIImageView!
  
  @IBInspectable var iconIndex: Int {
    get {
      return iconType.rawValue
    }

    set {
      iconType = IconType(rawValue: newValue) ?? .bolt

//      switch iconType {
//      case .bolt:
//        iconImageView.image = UIImage(named: "BoltColored")
//      case .chain:
//        iconImageView.image = UIImage(named: "ChainColored")
//      }
    }
  }
}
