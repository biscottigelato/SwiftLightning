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
  
  
  // MARK: Number Formatters
  
  override class var formatter: NumberFormatter {
    let _formatter = super.formatter
    _formatter.minimumFractionDigits = 0
    _formatter.maximumFractionDigits = 10
    _formatter.maximumIntegerDigits = 6  // 1 million bitcoins?
    
    _formatter.usesSignificantDigits = true
    _formatter.maximumSignificantDigits = 12
    return _formatter
  }
  
  class var bitFormatter: NumberFormatter {
    let _formatter = self.formatter
    _formatter.currencySymbol = "ƀ"
    _formatter.currencyCode = "bits"

    _formatter.multiplier = NSNumber(value: pow(10.0,6.0))
    
    _formatter.minimumFractionDigits = 0
    _formatter.maximumFractionDigits = 4
    _formatter.maximumIntegerDigits = 12  // 1 million bitcoins?
    
    return _formatter
  }
  
  class var satoshiFormatter: NumberFormatter {
    let _formatter = self.formatter
    _formatter.currencySymbol = "" //ṡ
    _formatter.currencyCode = "sats"

    _formatter.multiplier = NSNumber(value: pow(10.0,8.0))
    
    _formatter.minimumFractionDigits = 0
    _formatter.maximumFractionDigits = 2
    _formatter.maximumIntegerDigits = 14  // 1 million bitcoins?
    
    return _formatter
  }
  
  class var limitedFormatter: NumberFormatter {
    let _formatter = self.formatter

    _formatter.usesSignificantDigits = true
    _formatter.maximumSignificantDigits = 5
    return _formatter
  }
  
  
  // MARK: Convert to fundamental types
  
  var integerInSatoshis: Int {
    return Int(truncating: (amount as NSDecimalNumber).multiplying(byPowerOf10: -Int16(Constants.magnitudeOfSatoshi)))
  }
  
  var integerInBits: Int {
    return Int(truncating: (amount as NSDecimalNumber).multiplying(byPowerOf10: -Int16(Constants.magnitudeOfBit)))
  }
  
  
  // MARK: Initializers
  
  convenience init(_ money: Money<XBT>) {
    self.init(money.amount)
  }
  
  convenience init(inSatoshi integer: IntegerLiteralType) {
    self.init(integerLiteral: integer, magnitudeFromBaseUnit: Constants.magnitudeOfSatoshi)
  }
  
  convenience init?(inSatoshi string: String) {
    self.init(string, formatter: Bitcoin.satoshiFormatter)
  }
  
  convenience init(inBits integer: IntegerLiteralType) {
    self.init(integerLiteral: integer, magnitudeFromBaseUnit: Constants.magnitudeOfBit)
  }
  
  convenience init?(inBits string: String) {
    self.init(string, formatter: Bitcoin.bitFormatter)
  }
  
  
  // MARK: Comparable & Equatable Conformance
  
  static func ==(lhs: Bitcoin, rhs: Bitcoin) -> Bool {
    return lhs.amount == rhs.amount
  }
  
  static func ==(lhs: Bitcoin, rhs: Money<XBT>) -> Bool {
    return lhs.amount == rhs.amount
  }
  
  static func ==(lhs: Money<XBT>, rhs: Bitcoin) -> Bool {
    return lhs.amount == rhs.amount
  }
  
  static func <(lhs: Bitcoin, rhs: Bitcoin) -> Bool {
    return lhs.amount < rhs.amount
  }
  
  static func <(lhs: Bitcoin, rhs:Money<XBT>) -> Bool {
    return lhs.amount < rhs.amount
  }
  
  static func <(lhs: Money<XBT>, rhs:Bitcoin) -> Bool {
    return lhs.amount < rhs.amount
  }
  
  
  // MARK: Formatted Strings
  
  func formattedInSatoshis(using formatter: NumberFormatter = Bitcoin.satoshiFormatter) -> String {
    return formatter.string(from: amount as NSDecimalNumber)!
  }
  
  func formattedInBits(using formatter: NumberFormatter = Bitcoin.bitFormatter) -> String {
    return formatter.string(from: amount as NSDecimalNumber)!
  }
}
