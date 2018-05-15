//
//  SLLogoView.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-05-13.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class SLLogoView: UIImageView {

  struct Constants {
    static let logoAnimationDuration = TimeInterval(2.0)
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    initializeLogo()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initializeLogo()
  }
  
  private func initializeLogo() {
    self.image = UIImage(named: "LightningVector4")
    
    let animationImages = [UIImage(named: "LightningVector4")!,
                           UIImage(named: "LightningVector0")!,
                           UIImage(named: "LightningVector1")!,
                           UIImage(named: "LightningVector2")!,
                           UIImage(named: "LightningVector3")!]
    
    self.animationImages = animationImages
    self.animationDuration = Constants.logoAnimationDuration
  }
  
  
  // MARK: Semaphore
  
  private var semaphore = DispatchSemaphore(value: 1)
  private var numAnimationStarts: Int = 0
  
  func pushAnimate() {
    semaphore.wait()
    if numAnimationStarts <= 0 {
      startAnimating()
    }
    numAnimationStarts += 1
    semaphore.signal()
  }
  
  func popAnimate() {
    semaphore.wait()
    numAnimationStarts -= 1
    
    if numAnimationStarts < 0 {
      SLLog.warning("numAnimationStarts < 0")
      numAnimationStarts = 0
    }
    if numAnimationStarts <= 0 {
      stopAnimating()
    }
    semaphore.signal()
  }
}
