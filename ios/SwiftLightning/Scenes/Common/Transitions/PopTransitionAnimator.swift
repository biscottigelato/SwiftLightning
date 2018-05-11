//
//  PopTransitionAnimator.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2017-10-06.
//  Copyright © 2017 2018 BiscottiGelato. All rights reserved.
//

import UIKit

class PopTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
  
  // MARK: - Public Instance Variables
  
  var isPresenting: Bool = true
  var timingCurve: UIViewAnimationOptions = .curveEaseInOut
  var duration: TimeInterval
  
  
  // MARK: - Public Instance Functions
  
  init(transitionFor duration: TimeInterval) {
    self.duration = duration
    super.init()
  }
  
  override init() {
    SLLog.fatal("Initialization with no argument is not allowed")
  }
  
  func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
    return duration
  }
  
  func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
    
    guard let fromVC = transitionContext.viewController(forKey: .from), let toVC = transitionContext.viewController(forKey: .to) else {
      SLLog.assert("No From ViewController and/or To ViewController")
      return
    }

    let containerView = transitionContext.containerView
    let existingVCFrame = fromVC.view.frame
    let screeenBounds = UIScreen.main.bounds
    
    // Present Case
    if isPresenting {
      let origin = CGPoint(x: 0.0, y: existingVCFrame.origin.y + screeenBounds.height)  // Traverse the entire screen height for convenience sake
      toVC.view.frame = CGRect(origin: origin, size: existingVCFrame.size)
      containerView.addSubview(toVC.view)
      containerView.bringSubview(toFront: toVC.view)

      // Animate everything!
      UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, options: timingCurve, animations: {
        fromVC.view.alpha = 0.0
        fromVC.view.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        toVC.view.frame = existingVCFrame
      }, completion: { _ in
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
      })
    }
    
    // Dismiss Case
    else {
      // Set everything to a known state for toVC first
      toVC.view.transform = CGAffineTransform.identity
      toVC.view.frame = existingVCFrame
      
      // Now transform to the starting point
      toVC.view.alpha = 0.0
      toVC.view.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
      containerView.addSubview(toVC.view)
      containerView.bringSubview(toFront: fromVC.view)
      
      // Animate everything!
      UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, options: timingCurve, animations: {
        let origin = CGPoint(x: 0.0, y: existingVCFrame.origin.y + screeenBounds.height)  // Traverse the entire screen height for convenience sake
        fromVC.view.frame = CGRect(origin: origin, size: existingVCFrame.size)
        toVC.view.transform = CGAffineTransform.identity
        toVC.view.alpha = 1.0
      }, completion: { _ in
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
      })
    }
  }
}

