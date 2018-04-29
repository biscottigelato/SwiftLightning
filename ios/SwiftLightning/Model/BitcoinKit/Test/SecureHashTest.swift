//
//  SecureHashTest.swift
//  SwiftLightningTests
//
//  Created by Howard Lee on 2018-04-29.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import XCTest
@testable import SwiftLightning


class SecureHashTest: XCTestCase {
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testSHA256() {
    /* Usually, when a hash is computed within bitcoin, it is computed twice.
     Most of the time SHA-256 hashes are used, however RIPEMD-160 is also used when a shorter hash is desirable
     (for example when creating a bitcoin address).
     
     https://en.bitcoin.it/wiki/Protocol_documentation#Hashes
     */
    XCTAssertEqual(SecureHash.sha256("hello".data(using: .ascii)!), Data(hexString: "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"))
    XCTAssertEqual(SecureHash.sha256sha256("hello".data(using: .ascii)!), Data(hexString: "9595c9df90075148eb06860365df33584b75bff782a510c6cd4883a419833d50"))
  }
}
