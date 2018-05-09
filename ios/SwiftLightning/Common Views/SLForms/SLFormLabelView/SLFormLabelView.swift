//
//  SLFormLabelView.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-25.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class SLFormLabelView: NibView {
  
  // MARK: IBOutlets
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var textLabel: UILabel!
  @IBOutlet weak var refAmtLabel: UILabel!
  
  @IBOutlet weak var singleLabelHeight: NSLayoutConstraint!
  
  
  // MARK: View lifecycle
  
  var initialLayout = true
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    if initialLayout {
      initialLayout = false
      initLabelView(by: labelViewType)
    }
  }
  
  override var intrinsicContentSize: CGSize {
    return CGSize(width: SLDesign.Constants.defaultUIElementWidth, height: 2*singleLabelHeight.constant)
  }
  
  
  // MARK: Field Title
  
  @IBInspectable var title: String {
    get {
      return titleLabel.text ?? ""
    }
    set {
      titleLabel.text = newValue
    }
  }
  
  
  // MARK: Label View Type Configuration
  
  enum LabelType: Int {
    case text = 0
    case amount // 1
  }
  
  var labelViewType: LabelType = .text
  
  @IBInspectable var labelViewTypeIndex: Int {
    get {
      return labelViewType.rawValue
    }
    set {
      labelViewType = LabelType(rawValue: newValue) ?? .text
      initLabelView(by: labelViewType)
    }
  }
  
  private func initLabelView(by type: LabelType) {
    
    switch type {
    case .text:
      refAmtLabel.isHidden = true
      
    case .amount:
      refAmtLabel.isHidden = false
    }
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
}
