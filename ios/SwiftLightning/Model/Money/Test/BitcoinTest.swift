//
//  BitcoinTest.swift
//  SwiftLightningTests
//
//  Created by Howard Lee on 2018-04-25.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import XCTest
@testable import SwiftLightning

class BitcoinTest: XCTestCase {
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testBitcoinSymbolInit() {
    XCTAssertEqual(Bitcoin("₿123.456"), Bitcoin("123.456"))
  }
  
  func testXBTSymbolSpaceInit() {
    XCTAssertEqual(Money<XBT>("₿ 234.567"), Bitcoin("234.567"))
  }
  
  func testSatoshiCommaInit() {
    XCTAssertEqual(Bitcoin(inSatoshi: "987,654,321.0"), Bitcoin("9.87654321"))
  }
  
  func testBitIntLiteralInit() {
    XCTAssertEqual(Bitcoin(inBits: 13579), Bitcoin("0.013579"))
  }

  func testXBTAddCompatibility() {
    let xbtMoney = Money<XBT>("2.4678")! + Money<XBT>("1.1111")!
    let btcMoney = Bitcoin("1.3567")! + Bitcoin("2.2222")!
    XCTAssertEqual(btcMoney, xbtMoney)
  }
  
  func testInSatoshiFormattedOutput() {
    let bitcoin = Bitcoin("0.0001234567")
    XCTAssertEqual(bitcoin?.formattedInSatoshis(), "12,345.67")
  }
  
  func testInBitFormattedOutput() {
    let bitcoin = Bitcoin("0.0001234567")
    XCTAssertEqual(bitcoin?.formattedInBits(), "123.4567")
  }
  
  func testBitcoinPlainFormattedOutput() {
    let bitcoin = Bitcoin(inSatoshi: 12345678)
    let formatter = Bitcoin.formatter
    formatter.numberStyle = .decimal
    XCTAssertEqual(bitcoin.formatted(using: formatter), "0.12345678")
  }
  
  func testBitcoinSymboledFormattedOutput() {
    let bitcoin = Bitcoin(inBits: 9999123456)
    XCTAssertEqual(bitcoin.formatted(), "₿9,999.123456")
  }
  
  func testBitcoinLimitedFormattedOutput1() {
    let bitcoin = Bitcoin(inBits: 9999998765)
    let formatter = Bitcoin.limitedFormatter
    XCTAssertEqual(bitcoin.formatted(using: formatter), "₿10,000")
  }
  
  func testBitcoinLimitedFormattedOutput2() {
    let bitcoin = Bitcoin(inBits: "1234.5123")
    let formatter = Bitcoin.limitedFormatter
    XCTAssertEqual(bitcoin?.formatted(using: formatter), "₿0.0012345")
  }
}
