//
//  SLRandValuesTests.swift
//  SwiftLightningTests
//
//  Created by Howard Lee on 2018-04-19.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import XCTest
@testable import SwiftLightning

class SLRandValuesTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
  
    func testGetNumRandValues() {
      let startValue: UInt = 88
      let endValue: UInt = 201
      let valuesToGet: UInt = endValue - startValue + 1
      
      let valueArray: [UInt] = SLRandValues.get(valuesToGet, from: startValue, to: endValue)
      var validationArray = [UInt]()
      
      for value in valueArray {
        XCTAssert(!validationArray.contains(value))
        XCTAssert(value >= startValue)
        XCTAssert(value <= endValue)
        validationArray.append(value)
      }
      
      XCTAssert(valueArray.count == valuesToGet)
    }
  
  
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
