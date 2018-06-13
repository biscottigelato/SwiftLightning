//
//  Bitcoin.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-24.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation


struct XBT: Currency {
  static let code = ""  // For msat...
  static let symbol = ""
  static let baseUnit = ""
}


class Bitcoin: Money<XBT> {
  
  struct Constants {
    static let magnitudeOfBtcToMsat: Double = 11.0
    static let magnitudeOfBitToMsat: Double = 5.0
    static let magnitudeOfSatToMsat: Double = 3.0
  }
  
  
  // MARK: Number Formatters
  
  override class var formatter: NumberFormatter {  // denominate BTC in msat
    let _formatter = super.formatter
    _formatter.numberStyle = .decimal
    
    _formatter.minimumFractionDigits = 0
    _formatter.maximumFractionDigits = 0
    _formatter.maximumIntegerDigits = 17  // 1 million bitcoins?
    
    return _formatter
  }
  
  class var btcFormatter: NumberFormatter {
    let _formatter = self.formatter
    _formatter.currencySymbol = "₿"
    _formatter.currencyCode = "XBT"
    _formatter.numberStyle = .currency
    
    _formatter.multiplier = pow(10.0, -Constants.magnitudeOfBtcToMsat) as NSNumber
    
    _formatter.minimumFractionDigits = 0
    _formatter.maximumFractionDigits = 11
    _formatter.maximumIntegerDigits = 6  // 1 million bitcoins
    
    return _formatter
  }
  
  class var bitFormatter: NumberFormatter {
    let _formatter = self.formatter
    _formatter.currencySymbol = "ƀ"
    _formatter.currencyCode = "bits"
    _formatter.numberStyle = .currency

    _formatter.multiplier = pow(10.0, -Constants.magnitudeOfBitToMsat) as NSNumber
    
    _formatter.minimumFractionDigits = 0
    _formatter.maximumFractionDigits = 5
    _formatter.maximumIntegerDigits = 12  // 1 million bitcoins?
    
    return _formatter
  }
  
  class var satoshiFormatter: NumberFormatter {
    let _formatter = self.formatter
//    _formatter.currencySymbol = "" //ṡ
//    _formatter.currencyCode = "sats"
    _formatter.numberStyle = .decimal  // Change to decimal since no currency symbol anyways
    
    _formatter.multiplier = pow(10.0, -Constants.magnitudeOfSatToMsat) as NSNumber
    
    _formatter.minimumFractionDigits = 0
    _formatter.maximumFractionDigits = 3
    _formatter.maximumIntegerDigits = 14  // 1 million bitcoins?
    
    return _formatter
  }
  
  class var limitedFormatter: NumberFormatter {
    let _formatter = Bitcoin.btcFormatter

    _formatter.usesSignificantDigits = true
    _formatter.maximumSignificantDigits = 5
    return _formatter
  }
  
  
  // MARK: Convert to fundamental types
  
  var integerInSatoshis: Int {
    return Int(truncating: (amount as NSDecimalNumber).multiplying(byPowerOf10: Int16(-Constants.magnitudeOfSatToMsat)))
  }
  
  var integerInBits: Int {
    return Int(truncating: (amount as NSDecimalNumber).multiplying(byPowerOf10: Int16(-Constants.magnitudeOfBitToMsat)))
  }
  
  var integerInBtc: Int {
    return Int(truncating: (amount as NSDecimalNumber).multiplying(byPowerOf10: Int16(-Constants.magnitudeOfBtcToMsat)))
  }
  
  
  // MARK: Initializers
  
  convenience init(_ money: Money<XBT>) {
    self.init(money.amount)
  }
  
  convenience init(inSatoshi integer: IntegerLiteralType) {
    self.init(integerLiteral: integer, magnitudeFromBaseUnit: Int(Constants.magnitudeOfSatToMsat))
  }
  
  convenience init?(inSatoshi string: String) {
    self.init(string, formatter: Bitcoin.satoshiFormatter)
  }
  
  convenience init(inBits integer: IntegerLiteralType) {
    self.init(integerLiteral: integer, magnitudeFromBaseUnit: Int(Constants.magnitudeOfBitToMsat))
  }
  
  convenience init?(inBits string: String) {
    self.init(string, formatter: Bitcoin.bitFormatter)
  }
  
  convenience init?(inBtc integer: IntegerLiteralType) {
    self.init(integerLiteral: integer, magnitudeFromBaseUnit: Int(Constants.magnitudeOfBtcToMsat))
  }
  
  convenience init?(inBtc string: String) {
    self.init(string, formatter: Bitcoin.btcFormatter)
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
  
  func formattedInBtcs(using formatter: NumberFormatter = Bitcoin.btcFormatter) -> String {
    return formatter.string(from: amount as NSDecimalNumber)!
  }
}
