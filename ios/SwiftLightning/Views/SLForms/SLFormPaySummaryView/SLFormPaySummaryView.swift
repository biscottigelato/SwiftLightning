//
//  SLFormPaySummaryView.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-25.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class SLFormPaySummaryView: NibView {
  
  @IBOutlet weak var sendAmtLabel: UILabel!
  @IBOutlet weak var feeAmtLabel: UILabel!
  @IBOutlet weak var totalAmtLabel: UILabel!
  
  @IBOutlet weak var singleStackHeight: NSLayoutConstraint!
  
  override var intrinsicContentSize: CGSize {
    return CGSize(width: SLDesign.Constants.defaultUIElementWidth, height: 3*singleStackHeight.constant)
  }
}
