//
//  SLTextDialogView.swift

//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-23.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

class SLTextDialogView: NibView {
  
  @IBOutlet weak var textLabel: UILabel!
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    layer.cornerRadius = 15.0
    layer.masksToBounds = true
  }
  
  override var intrinsicContentSize: CGSize {
    let textSize = textLabel.intrinsicContentSize
    return CGSize(width: textSize.width + 60.0,
                  height: textSize.height + 40.0)
  }
}
