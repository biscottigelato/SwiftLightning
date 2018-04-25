//
//  Money.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-24.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation

protocol MoneyType: ExpressibleByFloatLiteral, ExpressibleByIntegerLiteral, CustomStringConvertible, Comparable {
  
  func formatted(withStyle style: NumberFormatter.Style) -> String
}

class Money<C: Currency>: MoneyType {
  
  static var formatter: NumberFormatter {
    let _formatter = NumberFormatter()
    _formatter.numberStyle = .currency
    _formatter.currencySymbol = C.symbol
    _formatter.currencyCode = C.code
    return _formatter
  }
  
  let amount: Decimal
  
  init(decimal: Decimal, magnitudeFromBaseUnit: Int = 0) {  // So magnitude here means 10^m. 10^0 = 1x, 10^2 = 100x, 10^-4 = 0.0001x
    let nsDecimal = decimal as NSDecimalNumber
    self.amount = nsDecimal.multiplying(byPowerOf10: Int16(magnitudeFromBaseUnit)) as Decimal
  }
  
  required init(floatLiteral value: FloatLiteralType) {
    self.amount = Decimal(value)
  }
  
  init(floatLiteral value: FloatLiteralType, magnitudeFromBaseUnit: Int = 0) {
    let nsDecimal = NSDecimalNumber(floatLiteral: value)
    self.amount = nsDecimal.multiplying(byPowerOf10: Int16(magnitudeFromBaseUnit)) as Decimal
  }
  
  required init(integerLiteral value: IntegerLiteralType) {
    self.amount = Decimal(value)
  }
  
  init(integerLiteral value: IntegerLiteralType, magnitudeFromBaseUnit: Int = 0) {
    let nsDecimal = NSDecimalNumber(integerLiteral: value)
    self.amount = nsDecimal.multiplying(byPowerOf10: Int16(magnitudeFromBaseUnit)) as Decimal
  }

  init?(string: String, magnitudeFromBaseUnit: Int = 0) {
    let nsDecimal = NSDecimalNumber(string: string)
    guard nsDecimal != NSDecimalNumber.notANumber else {
      SLLog.debug("String is not of numerical value")
      return nil
    }
    self.amount = nsDecimal.multiplying(byPowerOf10: Int16(magnitudeFromBaseUnit)) as Decimal
  }
  
  
  // MARK: Custom String Convertible Conformance
  
  var description: String {
    return formatted()
  }
  
  func formatted(withStyle style: NumberFormatter.Style = .currency) -> String {
    let formatter = Money<C>.formatter
    formatter.numberStyle = style
    return formatter.string(from: amount as NSDecimalNumber)!
  }
  
  
  // MARK: Comparable & Equatable Conformance
  
  static func ==<C: Currency>(lhs: Money<C>, rhs: Money<C>) -> Bool {
    return lhs.amount == rhs.amount
  }
  
  static func <<C: Currency>(lhs: Money<C>, rhs:Money<C>) -> Bool {
    return lhs.amount < rhs.amount
  }
}
