//
//  SLFormTextLabel.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-25.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class SLFormTextLabel: NibView {
  
  
  // MARK: IBOutlets

  @IBOutlet weak var textLabel: UILabel!
  @IBOutlet weak var singleLabelHeight: NSLayoutConstraint!
  
  
  override var intrinsicContentSize: CGSize {
    return CGSize(width: SLDesign.Constants.defaultUIElementWidth, height: singleLabelHeight.constant)
  }
  
  
  // MARK: Long Press Copy
  var copyDialogSuperview: UIView?
  
  @IBAction func longPressed(_ sender: UILongPressGestureRecognizer) {
    if let dialogSuperview = copyDialogSuperview, let copyText = textLabel.text {
      
      if copyText.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
        // This is what actually puts the text onto the clipboard
        UIPasteboard.general.string = copyText
        
        // This just shows a brief dialog to let the user know
        SLTextDialogView.show("Copied", on: dialogSuperview)
      }
    }
  }
  
  @IBInspectable var fontSize: CGFloat {
    get {
      return textLabel.font.pointSize
    }
    set {
      textLabel.font = UIFont.regularFont(newValue)
    }
  }
}
