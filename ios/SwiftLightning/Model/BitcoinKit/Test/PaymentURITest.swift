//
//  PaymentURITest.swift
//  BitcoinKit
//
//  Created by Kishikawa Katsumi on 2018/02/11.
//  Copyright © 2018 Kishikawa Katsumi. All rights reserved.
//

import XCTest
@testable import SwiftLightning


class PaymentURITest: XCTestCase {
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testPaymentURI() {
    let justAddress = try? PaymentURI("bitcoin:12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu")
    XCTAssertNotNil(justAddress)
    XCTAssertEqual(justAddress?.address, "12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu")
    XCTAssertNil(justAddress?.label)
    XCTAssertNil(justAddress?.message)
    XCTAssertNil(justAddress?.amount)
    XCTAssertTrue(justAddress?.others.isEmpty ?? false)
    XCTAssertEqual(justAddress?.uri, URL(string: "bitcoin:12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu"))
    
    let addressWithName = try? PaymentURI("bitcoin:12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu?label=Luke-Jr")
    XCTAssertNotNil(addressWithName)
    XCTAssertEqual(addressWithName?.address, "12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu")
    XCTAssertEqual(addressWithName?.label, "Luke-Jr")
    XCTAssertNil(addressWithName?.message)
    XCTAssertNil(addressWithName?.amount)
    XCTAssertTrue(addressWithName?.others.isEmpty ?? false)
    XCTAssertEqual(addressWithName?.uri, URL(string: "bitcoin:12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu?label=Luke-Jr"))
    
    let request20_30BTCToLukeJr = try? PaymentURI("bitcoin:12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu?amount=20.3&label=Luke-Jr")
    XCTAssertNotNil(request20_30BTCToLukeJr)
    XCTAssertEqual(request20_30BTCToLukeJr?.address, "12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu")
    XCTAssertEqual(request20_30BTCToLukeJr?.label, "Luke-Jr")
    XCTAssertEqual(request20_30BTCToLukeJr?.amount, Decimal(string: "20.30"))
    XCTAssertNil(request20_30BTCToLukeJr?.message)
    XCTAssertTrue(request20_30BTCToLukeJr?.others.isEmpty ?? false)
    XCTAssertEqual(request20_30BTCToLukeJr?.uri, URL(string: "bitcoin:12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu?amount=20.3&label=Luke-Jr"))
    
    let request50BTCWithMessage = try? PaymentURI("bitcoin:12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu?amount=50&label=Luke-Jr&message=Donation%20for%20project%20xyz")
    XCTAssertNotNil(request50BTCWithMessage)
    XCTAssertEqual(request50BTCWithMessage?.address, "12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu")
    XCTAssertEqual(request50BTCWithMessage?.label, "Luke-Jr")
    XCTAssertEqual(request50BTCWithMessage?.amount, Decimal(string: "50"))
    XCTAssertEqual(request50BTCWithMessage?.message, "Donation for project xyz")
    XCTAssertTrue(request50BTCWithMessage?.others.isEmpty ?? false)
    XCTAssertEqual(request50BTCWithMessage?.uri, URL(string: "bitcoin:12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu?amount=50&label=Luke-Jr&message=Donation%20for%20project%20xyz"))
    
    do {
      _ = try PaymentURI("bitcoin:12A1MyfXbW6RhdRAZEqofac5jCQQjwEPBu?amount=abc&label=Luke-Jr")
      XCTFail("Should fail")
    } catch PaymentURIError.malformed(let key) {
      XCTAssertEqual(key, .amount)
    } catch {
      XCTFail("Unexpected error")
    }
  }
  
}
