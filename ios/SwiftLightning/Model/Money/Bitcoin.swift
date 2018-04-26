//
//  Bitcoin.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-24.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation


struct XBT: Currency {
  static let code = "XBT"
  static let symbol = "₿"
  static let baseUnit = "BTC"
}


class Bitcoin: Money<XBT> {
  
  struct Constants {
    static let magnitudeOfSatoshi = -8
    static let magnitudeOfBit = -6
  }
  
  required init(floatLiteral value: FloatLiteralType) {
    super.init(floatLiteral: value)
  }
  
  required init(integerLiteral value: IntegerLiteralType) {
    super.init(integerLiteral: value)
  }
  
  init(_ money: Money<XBT>) {
    super.init(decimal: money.amount)
  }
  
  init(inSatoshi float: FloatLiteralType) {
    super.init(floatLiteral: float, magnitudeFromBaseUnit: Constants.magnitudeOfSatoshi)
  }
  
  init(inSatoshi integer: IntegerLiteralType) {
    super.init(integerLiteral: integer, magnitudeFromBaseUnit: Constants.magnitudeOfSatoshi)
  }
  
  init?(inSatoshi string: String) {
    super.init(string: string, magnitudeFromBaseUnit: Constants.magnitudeOfSatoshi)
  }
  
  init(inBits float: FloatLiteralType) {
    super.init(floatLiteral: float, magnitudeFromBaseUnit: Constants.magnitudeOfBit)
  }
  
  init(inBits integer: IntegerLiteralType) {
    super.init(integerLiteral: integer, magnitudeFromBaseUnit: Constants.magnitudeOfBit)
  }
  
  init?(inBits string: String) {
    super.init(string: string, magnitudeFromBaseUnit: Constants.magnitudeOfBit)
  }
  
  func formattedInSatoshis(withStyle style: NumberFormatter.Style = .currency) -> String {
    let formatter = Money<XBT>.formatter
    formatter.numberStyle = style
    formatter.multiplier = NSNumber(value: 10^(-Constants.magnitudeOfSatoshi))
    return formatter.string(from: amount as NSDecimalNumber)!
  }
  
  func formattedInBits(withStyle style: NumberFormatter.Style = .currency) -> String {
    let formatter = Money<XBT>.formatter
    formatter.numberStyle = style
    formatter.multiplier = NSNumber(value: 10^(-Constants.magnitudeOfBit))
    return formatter.string(from: amount as NSDecimalNumber)!
  }
}
