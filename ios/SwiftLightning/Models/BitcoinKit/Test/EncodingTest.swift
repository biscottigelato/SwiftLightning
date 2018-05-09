//
//  EncodingTest.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import XCTest
@testable import SwiftLightning


class EncodingTest: XCTestCase {
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testBase58_1() {
    XCTAssertEqual(Base58.decode("1EVEDmVcV7iPvTkaw2gk89yVcCzPzaS6B7").hexEncodedString(), "0093f051563b089897cb430602a7c35cd93b3cc8e9dfac9a96")
    XCTAssertEqual(Base58.decode("11ujQcjgoMNmbmcBkk8CXLWQy8ZerMtuN").hexEncodedString(), "00002c048b88f56727538eadb2a81cfc350355ee4c466740d9")
    XCTAssertEqual(Base58.decode("111oeV7wjVNCQttqY63jLFsg817aMEmTw").hexEncodedString(), "000000abdda9e604c965f5a2fe8c082b14fafecdc39102f5b2")
  }
  
  
  func testBase58_2() {
    do {
      let original = Data(hexString: "00010966776006953D5567439E5E39F86A0D273BEED61967F6")!
      
      let encoded = Base58.encode(original)
      XCTAssertEqual(encoded, "16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM")
      
      let decoded = Base58.decode(encoded)
      XCTAssertEqual(decoded.hexEncodedString(), original.hexEncodedString())
    }
  }
}
