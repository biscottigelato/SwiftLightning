//
//  Currency.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-24.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation

protocol Currency {
  static var code: String { get }
  static var symbol: String { get }
  static var baseUnit: String { get }
}


struct USD: Currency {
  static let code = "USD"
  static let symbol = "$"
  static let baseUnit = "USD"
}
