//
//  PersistentData.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-06-06.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation

class PersistentData {
  
  // MARK: Enum & Type Definitions
  
  enum Key: String {
    case achievedFirstSync
  }
  
  
  // MARK: Static Functions & Variables
  
  static let shared = PersistentData()
  
  
  // MARK: Public Functions & Variables
  
  private let defaults = UserDefaults.standard
  
  func set<T>(_ value: T?, forKey key: PersistentData.Key) {
    defaults.set(value, forKey: key.rawValue)
  }
  
  func get<T>(forKey key: PersistentData.Key) -> T? {
    switch T.self {
    case is URL.Type:
      return defaults.url(forKey: key.rawValue) as! T?
      
    case is [String : Any].Type:
      return defaults.dictionary(forKey: key.rawValue) as! T?
      
    case is String.Type:
      return defaults.string(forKey: key.rawValue) as! T?
      
    case is [String].Type:
      return defaults.stringArray(forKey: key.rawValue) as! T?
      
    case is Data.Type:
      return defaults.data(forKey: key.rawValue) as! T?
      
    case is Bool.Type:
      return defaults.bool(forKey: key.rawValue) as? T
      
    case is Int.Type:
      return defaults.integer(forKey: key.rawValue) as? T
      
    case is Float.Type:
      return defaults.float(forKey: key.rawValue) as? T
      
    case is Double.Type:
      return defaults.double(forKey: key.rawValue) as? T
      
    default:
      return defaults.object(forKey: key.rawValue) as! T?
    }
  }
  
  func getAll() -> [String : Any] {
    return defaults.dictionaryRepresentation()
  }
  
}
