//
//  Result.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-18.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation

enum Result<T> {
  case success(T)
  case failure(Error)
}
