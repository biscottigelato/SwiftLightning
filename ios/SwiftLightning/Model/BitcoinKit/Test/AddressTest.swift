//
//  AddressTest.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import XCTest
@testable import SwiftLightning


class AddressTest: XCTestCase {
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testAddress() {
    // Mainnet
    do {
      let address2 = try? Address("1AC4gh14wwZPULVPCdxUkgqbtPvC92PQPN")
      XCTAssertNotNil(address2)
    }
    
    do {
      _ = try Address("175tWpb8K1S7NmH4Zx6rewF9WQrcZv245W")
      XCTFail("Should throw invalid checksum error.")
    } catch AddressError.invalid {
      // Success
    } catch {
      XCTFail("Should throw invalid checksum error.")
    }
    
    // Testnet
    do {
      let address2 = try? Address("mjNkq5ycsAfY9Vybo9jG8wbkC5mbpo4xgC")
      XCTAssertNotNil(address2)
    }
  }
}
