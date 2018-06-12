//
//  SLSliderConfigView.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-06-10.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit
import SwiftRangeSlider

@IBDesignable class SLSliderConfigView: NibView {

  // MARK: - IBOutlet
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var valueLabel: UILabel!
  
  @IBOutlet weak var rangeSlider: RangeSlider!
  @IBOutlet weak var slider: UISlider!
  
  @IBOutlet weak var minMarkLabel: UILabel!
  @IBOutlet weak var secondMarkLabel: UILabel!
  @IBOutlet weak var thirdMarkLabel: UILabel!
  @IBOutlet weak var fourthMarkLabel: UILabel!
  @IBOutlet weak var maxMarkLabel: UILabel!
  
  override func layoutSubviews() {
    rangeSlider.layoutIfNeeded()
    rangeSlider.updateLayerFramesAndPositions()
  }
}
