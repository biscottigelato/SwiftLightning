//
//  SLFormEntryView.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-23.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class SLFormEntryView: NibView {
  
  // MARK: IBOutlets
  
  @IBOutlet var textFieldTapRecognizer: UITapGestureRecognizer!
  
  @IBOutlet weak var fieldTitleLabel: UILabel!
  @IBOutlet weak var textField: UITextField!
  @IBOutlet weak var convertedLabel: UILabel!
  @IBOutlet weak var button: SLBarButton!
  @IBOutlet weak var feeButton: UIButton!
  @IBOutlet weak var remainingLabel: UILabel!
  @IBOutlet weak var feeBalanceStack: UIStackView!
  
  @IBOutlet weak var topSpacerHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var bottomSpacerHeightConstraint: NSLayoutConstraint!
  
  
  // MARK: View lifecycle
  var initialLayout = true
  
  override func layoutSubviews() {
    super.layoutSubviews()
    
    if initialLayout {
      initialLayout = false
      initEntryView(by: entryViewType)
    }
  }
  
  
  // MARK: Intrinsic Size
  
  var intrinsicSize: CGSize = CGSize.zero
  
  override var intrinsicContentSize: CGSize {
    return intrinsicSize
  }
  
  enum EntryType: Int {
    case description = 0
    case key // 1
    case money // 2
    case moneyFeeBalance // 3
    case numberIPPort // 4
  }
  
  
  // MARK: Field Title
  
  @IBInspectable var fieldTitle: String {
    get {
      return fieldTitleLabel.text ?? ""
    }
    set {
      fieldTitleLabel.text = newValue
    }
  }
  
  
  // MARK: Entry View Type Configuration
  
  var entryViewType: EntryType = .description
  
  @IBInspectable var entryViewTypeIndex: Int {
    get {
      return entryViewType.rawValue
    }
    set {
      entryViewType = EntryType(rawValue: newValue) ?? .description
      initEntryView(by: entryViewType)
    }
  }
  
  private func initEntryView(by type: EntryType) {
    
    let spacerHeight = topSpacerHeightConstraint.constant + bottomSpacerHeightConstraint.constant
    
    switch type {
    case .description:
      let intrinsicHeight = 2*button.intrinsicContentSize.height + spacerHeight
      intrinsicSize = CGSize(width: SLDesign.Constants.defaultUIElementWidth, height: intrinsicHeight)
      
      textField.keyboardType = .default
      textField.autocapitalizationType = .sentences
      textField.autocorrectionType = .default
      convertedLabel.isHidden = true
      feeBalanceStack.isHidden = true
      button.isHidden = true
        
    case .key:
      let intrinsicHeight = 2*button.intrinsicContentSize.height + spacerHeight
      intrinsicSize = CGSize(width: SLDesign.Constants.defaultUIElementWidth, height: intrinsicHeight)
      
      textField.keyboardType = .namePhonePad
      textField.autocapitalizationType = .none
      textField.autocorrectionType = .yes //.no
      convertedLabel.isHidden = true
      feeBalanceStack.isHidden = true
      
      button.isHidden = false
      button.setTitle("Paste", for: .normal)
      
    case .money:
      let intrinsicHeight = 2*button.intrinsicContentSize.height + spacerHeight
      intrinsicSize = CGSize(width: SLDesign.Constants.defaultUIElementWidth, height: intrinsicHeight)
      
      textField.keyboardType = .decimalPad
      textField.autocapitalizationType = .none
      textField.autocorrectionType = .no
      textField.placeholder = "sat"  // TODO: Variable hint based on currency in use
      // convertedLabel.isHidden = false
      feeBalanceStack.isHidden = true
      
      button.isHidden = false
      button.setTitle("Swap", for: .normal)
      
    case .moneyFeeBalance:
      let intrinsicHeight = 2*button.intrinsicContentSize.height + spacerHeight
      intrinsicSize = CGSize(width: SLDesign.Constants.defaultUIElementWidth, height: intrinsicHeight)
      
      textField.keyboardType = .decimalPad
      textField.autocapitalizationType = .none
      textField.autocorrectionType = .no
      textField.placeholder = "sat"  // TODO: Variable hint based on currency in use
      // convertedLabel.isHidden = false
      // feeBalanceStack.isHidden = false
      
      button.isHidden = false
      button.setTitle("Swap", for: .normal)
      
    case .numberIPPort:
      let intrinsicHeight = 2*button.intrinsicContentSize.height + spacerHeight
      intrinsicSize = CGSize(width: SLDesign.Constants.defaultUIElementWidth, height: intrinsicHeight)
      
      textField.keyboardType = .numbersAndPunctuation
      textField.autocapitalizationType = .none
      textField.autocorrectionType = .no
      convertedLabel.isHidden = true
      feeBalanceStack.isHidden = true
      
      button.isHidden = false
      button.setTitle("Paste", for: .normal)
    }
    
    invalidateIntrinsicContentSize()
  }
  
  
  // MARK: Keyboard management
  
  
  
  // MARK: Text Field
  
  @IBAction func textFieldStackTapped(_ sender: UITapGestureRecognizer) {
    textField.becomeFirstResponder()
  }
  
}
