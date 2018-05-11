//
//  SlideTransitionAnimator.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2017-10-06.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

class SlideTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

  
  // MARK: - Public Instance Variables
  
  var presentDirection: BasicDirection
  var vcGap: CGFloat
  var duration: TimeInterval
  var isPresenting: Bool = true
  var timingCurve: UIViewAnimationOptions = .curveEaseInOut
  
  
  // MARK: - Public Instance Functions
  
  init(presentTowards direction: BasicDirection, withGapSize vcGap: CGFloat, transitionFor duration: TimeInterval) {
    self.presentDirection = direction
    self.vcGap = vcGap
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
    let screenBounds = UIScreen.main.bounds
    let existingVCFrame = fromVC.view.frame
    let presentingScalar: CGFloat = isPresenting ? 1.0 : -1.0
    var slideVector: CGPoint
    var oppoVector: CGPoint
    
    switch presentDirection {
    case .up:
      slideVector = CGPoint(x: existingVCFrame.origin.x, y: existingVCFrame.origin.y - presentingScalar*(screenBounds.height + vcGap))
      oppoVector = CGPoint(x: existingVCFrame.origin.x, y: existingVCFrame.origin.y + presentingScalar*(screenBounds.height + vcGap))
    case .down:
      slideVector = CGPoint(x: existingVCFrame.origin.x, y: existingVCFrame.origin.y + presentingScalar*screenBounds.height + vcGap)
      oppoVector = CGPoint(x: existingVCFrame.origin.x, y: existingVCFrame.origin.y - presentingScalar*screenBounds.height + vcGap)
    case .left:
      slideVector = CGPoint(x: existingVCFrame.origin.x - presentingScalar*(screenBounds.width + vcGap), y: existingVCFrame.origin.y)
      oppoVector = CGPoint(x: existingVCFrame.origin.x + presentingScalar*(screenBounds.width + vcGap), y: existingVCFrame.origin.y)
    case .right:
      slideVector = CGPoint(x: existingVCFrame.origin.x + presentingScalar*screenBounds.width + vcGap, y: existingVCFrame.origin.y)
      oppoVector = CGPoint(x: existingVCFrame.origin.x - presentingScalar*screenBounds.width + vcGap, y: existingVCFrame.origin.y)
    }
    
    // To View always starts opposite of Vector direction, off from Origin
    containerView.addSubview(toVC.view)
    toVC.view.frame = CGRect(origin: oppoVector, size: existingVCFrame.size)
    
    if isPresenting {
      containerView.bringSubview(toFront: toVC.view)
    } else {
      containerView.insertSubview(toVC.view, belowSubview: fromVC.view)
    }
  
    UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, options: timingCurve, animations: {
      toVC.view.frame = existingVCFrame
      fromVC.view.frame = CGRect(origin: slideVector, size: existingVCFrame.size)
    }, completion: { _ in
      transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
    })
  }
}
