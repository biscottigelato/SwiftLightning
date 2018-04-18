//
//  SLViewController.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-17.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

class SLViewController: UIViewController {
  
  
  
  
  // MARK: View lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Common Keyboard Management Registrations
    let keyboardDismissRecognizer = UITapGestureRecognizer(target: self, action: #selector(keyboardDismiss))
    keyboardDismissRecognizer.numberOfTapsRequired = 1
    keyboardDismissRecognizer.numberOfTouchesRequired = 1
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
  
  @objc private func keyboardDismiss() {
    self.view.endEditing(true)
  }
  
  @objc private func keyboardWillShow(_ notification: NSNotification) {
    if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
      // 20 as arbitrary value so there's some space between the text field in focus and the top of the keyboard
      keyboardScrollView?.contentInset.bottom = keyboardSize.height + 20.0
    }
  }
  
  @objc private func keyboardWillHide(_ notification: NSNotification) {
    keyboardScrollView?.contentInset.bottom = 0
  }
}
