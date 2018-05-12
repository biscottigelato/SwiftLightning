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
    case none = 0
    case bolt
    case chain
  }
  
  private var iconType: IconType = .bolt
  
  @IBOutlet private weak var iconImageView: UIImageView!
  
  func setIcon(to type: IconType) {
    iconType = type
    
    switch iconType {
    case .none:
      iconImageView.isHidden = true
    case .bolt:
      iconImageView.isHidden = false
      iconImageView.image = UIImage(named: "BoltColored")
    case .chain:
      iconImageView.isHidden = false
      iconImageView.image = UIImage(named: "ChainColored")
    }
  }
  
  @IBInspectable var iconIndex: Int {
    get {
      return iconType.rawValue
    }
    set {
      setIcon(to: IconType(rawValue: newValue) ?? .none)
    }
  }
}
