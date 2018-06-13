//
//  Money.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-24.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation

protocol MoneyType: ExpressibleByIntegerLiteral, CustomStringConvertible, Comparable {
  
  func formatted(using formatter: NumberFormatter?) -> String
}

class Money<C: Currency>: MoneyType {
  
  class var formatter: NumberFormatter {
    let _formatter = NumberFormatter()
    _formatter.numberStyle = .currency
    _formatter.currencySymbol = C.symbol
    _formatter.currencyCode = C.code
    
    _formatter.isLenient = true
    _formatter.generatesDecimalNumbers = true
    return _formatter
  }
  
  let amount: Decimal
  
  init(_ decimal: Decimal, magnitudeFromBaseUnit: Int = 0) {  // So magnitude here means 10^m. 10^0 = 1x, 10^2 = 100x, 10^-4 = 0.0001x
    let nsDecimal = decimal as NSDecimalNumber
    self.amount = nsDecimal.multiplying(byPowerOf10: Int16(magnitudeFromBaseUnit)) as Decimal
  }
  
  required init(integerLiteral value: IntegerLiteralType) {
    self.amount = Decimal(value)
  }
  
  init(integerLiteral value: IntegerLiteralType, magnitudeFromBaseUnit: Int = 0) {
    let nsDecimal = NSDecimalNumber(integerLiteral: value)
    self.amount = nsDecimal.multiplying(byPowerOf10: Int16(magnitudeFromBaseUnit)) as Decimal
  }

  init?(_ string: String, formatter: NumberFormatter = Money<C>.formatter) {
    guard let nsDecimal = formatter.number(from: string) as? NSDecimalNumber,
      nsDecimal != NSDecimalNumber.notANumber else {
      SLLog.debug("String is not of valid numerical value")
      return nil
    }
    self.amount = nsDecimal as Decimal
  }
  
  
  // MARK: Custom String Convertible Conformance
  
  var description: String {
    return formatted()
  }
  
  func formatted(using formatter: NumberFormatter? = nil) -> String {
    let numberFormatter = formatter ?? type(of: self).formatter
    return numberFormatter.string(from: amount as NSDecimalNumber)!
  }
  
  
  // MARK: Convert to fundamental types
  
  var integer: Int {
    return Int(truncating: (amount as NSDecimalNumber))
  }

  var double: Double? {  // Making this an optional just as a reminder this is dangerous
    return Double(truncating: (amount as NSDecimalNumber))
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
    return Money(amount + addend.amount)
  }
  
  func subtracting(by subtrahend: Money) -> Money {
    return Money(amount - subtrahend.amount)
  }
  
  func multiplying(by multiplier: Money) -> Money {
    return Money(amount * multiplier.amount)
  }
  
  func dividing(by divisor: Money) -> Money {
    return Money(amount / divisor.amount)
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

  
  // Multiplication
  // Explicitly not allow 2 money types to multiply together. Doesn't make sense to do so
  
  static func *(lhs: Money, rhs: IntegerLiteralType) -> Money {
    return lhs.multiplying(by: Money(integerLiteral: rhs))
  }
  
  static func *(lhs: IntegerLiteralType, rhs: Money) -> Money {
    return Money(integerLiteral: lhs).multiplying(by: rhs)
  }

  
  // Division
  // Explicitly not allow literal types to be divided by money type
  
  static func /(lhs: Money, rhs: Money) -> Money {
    return lhs.dividing(by: rhs)
  }
  
  static func /(lhs: Money, rhs: IntegerLiteralType) -> Money {
    return lhs / Money(integerLiteral: rhs)
  }
}


