//
//  SLViewController.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-17.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

class SLViewController: UIViewController {
  
  struct Constants {
    static let keyboardTravelDuation: Double = 0.3  // seconds
  }
  
  // MARK: View lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Common Keyboard Management Registrations
    let keyboardDismissRecognizer = UITapGestureRecognizer(target: self, action: #selector(keyboardDismiss))
    keyboardDismissRecognizer.numberOfTapsRequired = 1
    keyboardDismissRecognizer.numberOfTouchesRequired = 1
    keyboardDismissRecognizer.cancelsTouchesInView = false
    view.addGestureRecognizer(keyboardDismissRecognizer)
    
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  // MARK: Keyboard Management
  
  var keyboardScrollView: UIScrollView?
  var keyboardConstraint: NSLayoutConstraint?
  var keyboardConstraintMargin: CGFloat?
  
  @objc private func keyboardDismiss() {
    self.view.endEditing(true)
  }
  
  @objc private func keyboardWillShow(_ notification: NSNotification) {
    if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
      if keyboardScrollView != nil && keyboardConstraint != nil {
        SLLog.fatal("Both keyboardScrollView and keyboardConstraint set")
      }
      
      if keyboardConstraint != nil && keyboardConstraintMargin == nil {
        SLLog.fatal("keyboardConstraint set but keyboardHiddenConstraintValue not set")
      }
      
      var travelDistance: CGFloat = 1
      
      if let keyboardScrollView = keyboardScrollView {
        // 20 as arbitrary value so there's some space between the text field in focus and the top of the keyboard
        keyboardScrollView.contentInset.bottom = keyboardSize.height + 20.0
        travelDistance = keyboardSize.height + 20.0
      }
      
      if let keyboardConstraint = keyboardConstraint {
        travelDistance = abs((keyboardSize.height + keyboardConstraintMargin!) - keyboardConstraint.constant)
        keyboardConstraint.constant = keyboardSize.height + keyboardConstraintMargin!
      }
      
      let animationDuration = Constants.keyboardTravelDuation * Double(travelDistance / keyboardSize.height)

      UIView.animate(withDuration: animationDuration) {
        self.view.layoutIfNeeded()
      }
    }
  }
  
  @objc private func keyboardWillHide(_ notification: NSNotification) {

    keyboardScrollView?.contentInset.bottom = 0
    keyboardConstraint?.constant = keyboardConstraintMargin!
    
    UIView.animate(withDuration: Constants.keyboardTravelDuation) {
      self.view.layoutIfNeeded()
    }
  }
}
