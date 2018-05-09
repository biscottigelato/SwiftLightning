//
//  PaymentURI.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import Foundation

public struct PaymentURI {
  public let address: String  // Address
  public let label: String?
  public let message: String?
  public let amount: Decimal?
  public let others: [String: String]
  public let uri: URL
  
  public enum Keys : String {
    case address
    case label
    case message
    case amount
    case url
  }
  
  public init(addr: Address, amount: String? = nil, label: String? = nil, message: String? = nil) throws {
    var urlComponents = URLComponents()
    urlComponents.scheme = "bitcoin"
    urlComponents.path = addr.base58
    
    self.address = addr.base58
    self.label = label
    self.message = message
    self.others = [String: String]()
    
    var queryItems = [URLQueryItem]()
    if let amount = amount {
      queryItems.append(URLQueryItem(name: "amount", value: amount))
      
      guard let decimal = Decimal(string: amount) else {
        throw PaymentURIError.malformed(.amount)
      }
      self.amount = decimal
    } else {
      self.amount = nil
    }
    
    if let label = label {
      queryItems.append(URLQueryItem(name: "label", value: label))
    }
    if let message = message {
      queryItems.append(URLQueryItem(name: "message", value: message))
    }
    if !queryItems.isEmpty {
      urlComponents.queryItems = queryItems
    }
    
    guard let url = urlComponents.url else {
      throw PaymentURIError.malformed(.url)
    }
    self.uri = url
  }
  
  public init(_ string: String) throws {
    guard let components = URLComponents(string: string), let scheme = components.scheme, scheme.lowercased() == "bitcoin" else {
      throw PaymentURIError.invalid
    }
//    guard let address = try? Address(components.path) else {
//        throw PaymentURIError.malformed(.address)
//    }
    
    self.address = components.path  // Putting the raw value in here for now. Validate the address later
    self.uri = components.url!
    
    guard let queryItems = components.queryItems else {
      self.label = nil
      self.message = nil
      self.amount = nil
      self.others = [:]
      return
    }
    
    var label: String?
    var message: String?
    var amount: Decimal?
    var others = [String: String]()
    for queryItem in queryItems {
      
      var queryItemName = queryItem.name
      let required = queryItemName.hasPrefix("req-")
      
      if required {
        queryItemName = String(queryItemName.dropFirst(4))
      }
      
      switch queryItem.name {
      case Keys.label.rawValue:
        label = queryItem.value
      case Keys.message.rawValue:
        message = queryItem.value
      case Keys.amount.rawValue:
        if let v = queryItem.value, let value = Decimal(string: v) {
          amount = value
        } else {
          throw PaymentURIError.malformed(.amount)
        }
      default:
        if required {
          throw PaymentURIError.invalid
        }
        if let value = queryItem.value {
          others[queryItem.name] = value
        }
      }
    }
    self.label = label
    self.message = message
    self.amount = amount
    self.others = others
  }
}

enum PaymentURIError : Error {
  case invalid
  case malformed(PaymentURI.Keys)
}
