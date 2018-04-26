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
  
  
  // MARK: Basic Arithmetic Operations
  
  func adding(by addend: Money) -> Money {
    return Money(decimal: amount + addend.amount)
  }
  
  func subtracting(by subtrahend: Money) -> Money {
    return Money(decimal: amount - subtrahend.amount)
  }
  
  func multiplying(by multiplier: Money) -> Money {
    return Money(decimal: amount * multiplier.amount)
  }
  
  func dividing(by divisor: Money) -> Money {
    return Money(decimal: amount / divisor.amount)
  }
  
  
  // MARK: Operator Overloading
  
  // Addition
  
  static func +(lhs: Money, rhs: Money) -> Money {
    return lhs.adding(by: rhs)
  }
  
  static func +(lhs: Money, rhs: IntegerLiteralType) -> Money {
    return lhs + Money(integerLiteral: rhs)
  }
  
  static func +(lhs: IntegerLiteralType, rhs: Money) -> Money {
    return Money(integerLiteral: lhs) + rhs
  }
  
  static func +(lhs: Money, rhs: FloatLiteralType) -> Money {
    return lhs + Money(floatLiteral: rhs)
  }
  
  static func +(lhs: FloatLiteralType, rhs: Money) -> Money {
    return Money(floatLiteral: lhs) + rhs
  }
  
  // Subtraction
  
  static func -(lhs: Money, rhs: Money) -> Money {
    return lhs.subtracting(by: rhs)
  }
  
  static func -(lhs: Money, rhs: IntegerLiteralType) -> Money {
    return lhs - Money(integerLiteral: rhs)
  }
  
  static func -(lhs: IntegerLiteralType, rhs: Money) -> Money {
    return Money(integerLiteral: lhs) - rhs
  }
  
  static func -(lhs: Money, rhs: FloatLiteralType) -> Money {
    return lhs - Money(floatLiteral: rhs)
  }
  
  static func -(lhs: FloatLiteralType, rhs: Money) -> Money {
    return Money(floatLiteral: lhs) - rhs
  }
  
  // Multiplication
  // Explicitly not allow 2 money types to multiply together. Doesn't make sense to do so
  
  static func *(lhs: Money, rhs: IntegerLiteralType) -> Money {
    return lhs.multiplying(by: Money(integerLiteral: rhs))
  }
  
  static func *(lhs: IntegerLiteralType, rhs: Money) -> Money {
    return Money(integerLiteral: lhs).multiplying(by: rhs)
  }
  
  static func *(lhs: Money, rhs: FloatLiteralType) -> Money {
    return lhs.multiplying(by: Money(floatLiteral: rhs))
  }
  
  static func *(lhs: FloatLiteralType, rhs: Money) -> Money {
    return Money(floatLiteral: lhs).multiplying(by: rhs)
  }
  
  // Division
  // Explicitly not allow literal types to be divided by money type
  
  static func /(lhs: Money, rhs: Money) -> Money {
    return lhs.subtracting(by: rhs)
  }
  
  static func /(lhs: Money, rhs: IntegerLiteralType) -> Money {
    return lhs / Money(integerLiteral: rhs)
  }
  
  static func /(lhs: Money, rhs: FloatLiteralType) -> Money {
    return lhs / Money(floatLiteral: rhs)
  }
}


