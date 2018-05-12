//
//  SLFormDebugLevelView.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-05-11.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit


protocol SLFormDebugLevelViewDelegate {
  func stringsForLevel(_ debugLevelView: SLFormDebugLevelView) -> [String]
  func debugLevelView(_ debugLevelView: SLFormDebugLevelView, didSelectLevel level: Int)
  func debugLevelViewExpanded(_ debugLevelView: SLFormDebugLevelView)
}


@IBDesignable class SLFormDebugLevelView: NibView, UIPickerViewDelegate, UIPickerViewDataSource {

  @IBOutlet weak var subSystemLabel: UILabel!
  @IBOutlet weak var levelLabel: UILabel!
  @IBOutlet private weak var picker: UIPickerView! {
    didSet {
      picker.delegate = self
      picker.dataSource = self
    }
  }
  @IBOutlet weak var lineView2: UIView!
  
  
  @IBOutlet private weak var labelsHeightConstraint: NSLayoutConstraint!
  
  var delegate: SLFormDebugLevelViewDelegate?
  
  override var intrinsicContentSize: CGSize {
    let width = SLDesign.Constants.defaultUIElementWidth
    var height: CGFloat
    if picker.isHidden || picker.alpha == 0.0 {
      height = labelsHeightConstraint.constant + 1  // For 1 line
    } else {
      height = labelsHeightConstraint.constant + picker.intrinsicContentSize.height + 2  // For 2 lines
    }
    return CGSize(width: width, height: height)
  }
  
  @IBInspectable var subSystemText: String? {
    get {
      return subSystemLabel.text
    }
    set {
      subSystemLabel.text = newValue
    }
  }
  
  
  // MARK: Picker
  
  var levelsStringsArray: String?
  
  func numberOfComponents(in pickerView: UIPickerView) -> Int { return 1 }
  
  func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
    guard let delegate = delegate else { return 0 }
    return delegate.stringsForLevel(self).count
  }
  
  func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
    guard let delegate = delegate else { return nil }
    return delegate.stringsForLevel(self)[row]
  }
  
  func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
    levelLabel.text = delegate?.stringsForLevel(self)[row]
    delegate?.debugLevelView(self, didSelectLevel: row)
  }
  
  func togglePicker(forceHide: Bool = false, forceShow: Bool = false) {
    guard !forceHide || !forceShow else {
      SLLog.fatal("Cannot have both force show and force hide on at the same time")
    }
    
    if forceHide, !picker.isHidden {
      picker.alpha = 0.0
      picker.isHidden = true
      lineView2.isHidden = true
      self.invalidateIntrinsicContentSize()
      
    } else if forceShow, picker.isHidden {
      picker.alpha = 1.0
      picker.isHidden = false
      lineView2.isHidden = false
      self.invalidateIntrinsicContentSize()
      
    } else if !forceShow, !forceHide {
      if picker.alpha == 0.0 {
        picker.alpha = 1.0
        picker.isHidden = false
        lineView2.isHidden = false
      }
      else {
        picker.alpha = 0.0
        picker.isHidden = true
        lineView2.isHidden = true
      }
      self.invalidateIntrinsicContentSize()
    }
  }
  
  var selectedRow: Int {
    return picker.selectedRow(inComponent: 0)
  }
  
  
  // MARK: Tap Management
  
  @IBOutlet weak var tapArrowView: UIImageView!
  
  @IBAction func labelStackTapped(_ sender: UITapGestureRecognizer) {
    UIView.animate(withDuration: SLDesign.Constants.defaultTransitionDuration) {
      if self.picker.isHidden {
        self.picker.alpha = 1.0
        self.picker.isHidden = false
        self.lineView2.isHidden = false
        self.tapArrowView.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
      }
      else {
        self.picker.alpha = 0.0
        self.picker.isHidden = true
        self.lineView2.isHidden = true
        self.tapArrowView.transform = CGAffineTransform.identity
      }
      self.invalidateIntrinsicContentSize()
      self.delegate?.debugLevelViewExpanded(self)
    }
  }
}
