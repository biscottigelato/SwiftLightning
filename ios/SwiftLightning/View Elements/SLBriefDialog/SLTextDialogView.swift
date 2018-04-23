//
//  SLTextDialogView.swift

//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-23.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

class SLTextDialogView: NibView {
  
  struct Constants {
    static let transitionDuration: Double = 0.3
    static let appearanceDuration: Double = 2.0
  }
  
  @IBOutlet weak var textLabel: UILabel!
  
  static func show(_ dialogText: String, on view: UIView) {
    
    let copiedDialog = SLTextDialogView()
    copiedDialog.textLabel.text = dialogText
    copiedDialog.alpha = 0.0
    
    view.addSubview(copiedDialog)
    copiedDialog.snp.makeConstraints { make in
      make.center.equalTo(view)
    }
    
    UIView.animate(withDuration: Constants.transitionDuration) {  // TODO: Consider factoring these out
      copiedDialog.alpha = 1.0
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + Constants.appearanceDuration) {  // TODO: Consider factoring these out
      UIView.animate(withDuration: Constants.transitionDuration, animations: {
        copiedDialog.alpha = 0.0
      }, completion: { (complete) in
        copiedDialog.removeFromSuperview()
      })
    }
  }
  
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
