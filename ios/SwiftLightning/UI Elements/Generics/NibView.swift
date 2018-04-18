//
//  NibView.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-17.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

class NibView: UIView {
  var view: UIView!
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    xibSetup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    xibSetup()
  }
  
  func xibSetup() {
    backgroundColor = UIColor.clear
    view = loadNib()
    view.frame = bounds
    addSubview(view)
    
    view.translatesAutoresizingMaskIntoConstraints = false
    addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[childView]|",
                                                  options: [],
                                                  metrics: nil,
                                                  views: ["childView": view]))
    addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[childView]|",
                                                  options: [],
                                                  metrics: nil,
                                                  views: ["childView": view]))
  }
  
  /** Loads instance from nib with the same name. */
  func loadNib() -> UIView {
    let bundle = Bundle(for: type(of: self))
    let nibName = type(of: self).description().components(separatedBy: ".").last!
    let nib = UINib(nibName: nibName, bundle: bundle)
    return nib.instantiate(withOwner: self, options: nil).first as! UIView
  }
}
