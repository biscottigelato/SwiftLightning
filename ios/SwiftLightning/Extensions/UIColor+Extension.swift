//
//  UIColor+Extension.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-17.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

extension UIColor {
  
  static let darkTextBlue = UIColor(named: "DarkTextBlue")!
  static let disabledGray = UIColor(named: "DisabledGray")!
  static let disabledGrayShadow = UIColor(named: "DisabledGrayShadow")!
  static let disabledText = UIColor(named: "DisabledText")!
  static let formBackground = UIColor(named: "FormBackground")!
  static let formShadow = UIColor(named: "FormShadow")!
  static let genericGray = UIColor(named: "GenericGray")!
  static let genericGrayShadow = UIColor(named: "GenericGrayShadow")!
  static let jellyBeanRed = UIColor(named: "JellyBeanRed")!
  static let jellyBeanRedShadow = UIColor(named: "JellyBeanRedShadow")!
  static let lightAzureBlue = UIColor(named: "LightAzureBlue")
  static let lightAzureBlueShadow = UIColor(named: "LightAzureBlueShadow")!
  static let lightTextGray = UIColor(named: "LightTextGray")!
  static let medAquamarine = UIColor(named: "MedAquamarine")!
  static let medAquamarineShadow = UIColor(named: "MedAquamarineShadow")!
  static let mediumTextGray = UIColor(named: "MediumTextGray")!
  static let normalText = UIColor(named: "NormalText")!
  static let sandyOrange = UIColor(named: "SandyOrange")!
  static let sandyOrangeShadow = UIColor(named: "SandyOrangeShadow")!
  static let spaceCadetBlue = UIColor(named: "SpaceCadetBlue")!
  
  static func from(hex hexString: String) -> UIColor {
    var cString:String = hexString.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    
    if (cString.hasPrefix("#")) {
      cString.remove(at: cString.startIndex)
    }
    
    if ((cString.count) != 6) {
      return UIColor.gray
    }
    
    var rgbValue:UInt32 = 0
    Scanner(string: cString).scanHexInt32(&rgbValue)
    
    return UIColor(
      red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
      green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
      blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
      alpha: CGFloat(1.0)
    )
  }
}
