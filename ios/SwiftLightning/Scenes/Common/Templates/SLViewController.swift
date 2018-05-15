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
    
    // Animated Transition Constants
    fileprivate static let DragVelocityToDismiss: CGFloat = 800.0
    fileprivate static let DefaultSlideVCGap: CGFloat = 30.0
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
    
    // Drag dismiss transition animator
    if let dragGestureRecognizer = dragGestureRecognizer {
      view.addGestureRecognizer(dragGestureRecognizer)
    }
  }
  
//  override func viewWillDisappear(_ animated: Bool) {
//    super.viewWillDisappear(animated)
//    self.view.endEditing(true)
//  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    navigationController?.delegate = self  // So the Transition Delegate is set properly if dismisses
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  
  // MARK: Keyboard Management
  
  var keyboardScrollView: UIScrollView?
  var keyboardConstraint: NSLayoutConstraint?
  var keyboardConstraintMargin: CGFloat?
  private(set) var keyboardIsShown: Bool = false
  
  
  @objc private func keyboardDismiss() {
    self.view.endEditing(true)
  }
  
  @objc private func keyboardWillShow(_ notification: NSNotification) {
    keyboardIsShown = true
    
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
    keyboardIsShown = false
    keyboardScrollView?.contentInset.bottom = 0
    keyboardConstraint?.constant = keyboardConstraintMargin!
    
    UIView.animate(withDuration: Constants.keyboardTravelDuation) {
      self.view.layoutIfNeeded()
    }
  }
  
  
  // MARK: Animated Transition
  
  var animator: UIViewControllerAnimatedTransitioning?
  var transitionInteractor: PercentInteractor?
  var dragGestureRecognizer: UIPanGestureRecognizer?
  
  
  func pushPresent(_ viewController: SLViewController, animated: Bool) {
    if let navigationController = navigationController {
      navigationController.delegate = viewController
      navigationController.pushViewController(viewController, animated: animated)
    }
    else {
      present(viewController, animated: animated)
    }
  }
  
  
  func popDismiss(animated: Bool) {
    if let navigationController = navigationController {
      navigationController.popViewController(animated: animated)
    }
    else {
      dismiss(animated: animated)
    }
  }
  
  
  func setSlideTransition(presentTowards direction: BasicDirection,
                          withGapSize gapSize: CGFloat = Constants.DefaultSlideVCGap,
                          dismissIsInteractive: Bool,
                          duration: TimeInterval = SLDesign.Constants.defaultTransitionDuration) {
    
    guard direction == .left || direction == .right else {
      SLLog.assert("Only slide transitions of .left or .right is supported")
      return
    }
    
    self.animator = SlideTransitionAnimator(presentTowards: direction, withGapSize: gapSize, transitionFor: duration)
    self.navigationController?.delegate = self  // This will usually be nil. The Pusher needs to set the navigationControllerDelegate
    self.transitioningDelegate = self
    
    if dismissIsInteractive {
      self.dragGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
      self.transitionInteractor = PercentInteractor()
    }
  }
  
  func setPopTransition(dismissIsInteractive: Bool,
                        duration: TimeInterval = SLDesign.Constants.defaultTransitionDuration) {
    
    self.animator = PopTransitionAnimator(transitionFor: duration)
    self.navigationController?.delegate = self  // This will usually be nil. The Pusher needs to set the navigationControllerDelegate
    self.transitioningDelegate = self
    
    if dismissIsInteractive {
      self.dragGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureAction(_:)))
      self.transitionInteractor = PercentInteractor()
    }
  }
  
  
  @objc private func panGestureAction(_ panGesture: UIPanGestureRecognizer) {
    guard let transitionInteractor = transitionInteractor else {
      SLLog.assert("No Transition Interactor even tho dragGestureRecognizer is set")
      return
    }
    
    let gestureTranslation = panGesture.translation(in: view.superview!)
    let gestureVelocity = panGesture.velocity(in: view.superview!)
    let screenBounds = UIScreen.main.bounds
    var directionalVelocity: CGFloat
    var progress: CGFloat
    
    if let animator = animator as? SlideTransitionAnimator {
      
      // This is ever only used for dismiss! So we gotta do opposite below
      switch animator.presentDirection {
      case .down:
        let directionalTranslation = min(gestureTranslation.y, 0.0)
        directionalVelocity = min(gestureVelocity.y, 0.0)
        progress = abs(directionalTranslation)/(screenBounds.height + animator.vcGap)
        
      case .up:
        let directionalTranslation = max(gestureTranslation.y, 0.0)
        directionalVelocity = max(gestureVelocity.y, 0.0)
        progress = abs(directionalTranslation)/(screenBounds.height + animator.vcGap)
        
      case .right:
        let directionalTranslation = min(gestureTranslation.x, 0.0)
        directionalVelocity = min(gestureVelocity.x, 0.0)
        progress = abs(directionalTranslation)/(screenBounds.width + animator.vcGap)
        
      case .left:
        let directionalTranslation = max(gestureTranslation.x, 0.0)
        directionalVelocity = max(gestureVelocity.x, 0.0)
        progress = abs(directionalTranslation)/(screenBounds.width + animator.vcGap)
      }
      
      switch panGesture.state {
      case .began:
        animator.timingCurve = .curveLinear
        transitionInteractor.hasStarted = true
        popDismiss(animated: true)
        
      case .changed:
        transitionInteractor.update(progress)
        
      case .ended:
        if directionalVelocity >= Constants.DragVelocityToDismiss {
          transitionInteractor.hasStarted = false
          animator.timingCurve = .curveEaseInOut
          transitionInteractor.finish()
        } else {
          fallthrough
        }
        
      default:
        transitionInteractor.hasStarted = false
        animator.timingCurve = .curveEaseInOut
        transitionInteractor.cancel()
      }
    }
      
    else if let animator = animator as? PopTransitionAnimator {
      
      // This is ever only used for dismiss! So we gotta do opposite below
      let directionalTranslation = max(gestureTranslation.y, 0.0)
      directionalVelocity = max(gestureVelocity.y, 0.0)
      progress = abs(directionalTranslation)/(screenBounds.height)

      
      switch panGesture.state {
      case .began:
        animator.timingCurve = .curveLinear
        transitionInteractor.hasStarted = true
        popDismiss(animated: true)
        
      case .changed:
        transitionInteractor.update(progress)
        
      case .ended:
        if directionalVelocity >= Constants.DragVelocityToDismiss {
          transitionInteractor.hasStarted = false
          animator.timingCurve = .curveEaseInOut
          transitionInteractor.finish()
        } else {
          fallthrough
        }
        
      default:
        transitionInteractor.hasStarted = false
        animator.timingCurve = .curveEaseInOut
        transitionInteractor.cancel()
      }
    }
  }
}


// MARK: - ViewController Transition Delegate Protocol
extension SLViewController: UIViewControllerTransitioningDelegate {

  func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    if let animator = animator as? SlideTransitionAnimator {
      animator.isPresenting = true
      return animator
    } else if let animator = animator as? PopTransitionAnimator {
      animator.isPresenting = true
      return animator
    }
    return nil
  }
  
  func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
    return nil
  }
  
  func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    if let animator = animator as? SlideTransitionAnimator {
      animator.isPresenting = false
      return animator
    } else if let animator = animator as? PopTransitionAnimator {
      animator.isPresenting = false
      return animator
    }
    return nil
  }
  
  func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
    if let transitionInteractor = transitionInteractor {
      return transitionInteractor.hasStarted ? transitionInteractor : nil
    } else {
      return nil
    }
  }
}



// MARK: - Navigation Controller Transition Delegate Protocol
extension SLViewController: UINavigationControllerDelegate {
  
  func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
    if operation == .push {
      if let animator = animator as? SlideTransitionAnimator {
        animator.isPresenting = true
      } else if let animator = animator as? PopTransitionAnimator {
        animator.isPresenting = true
      }
    } else if operation == .pop {
      if let animator = animator as? SlideTransitionAnimator {
        animator.isPresenting = false
      } else if let animator = animator as? PopTransitionAnimator {
        animator.isPresenting = false
      }
    }
    return animator
  }
  
  func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
    if let transitionInteractor = transitionInteractor {
      return transitionInteractor.hasStarted ? transitionInteractor : nil
    } else {
      return nil
    }
  }
}

