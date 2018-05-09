//
//  Bech32Test.swift
//  SwiftLightningTests
//
//  Created by Alexander Bosworth on 3/21/17.
//  Copyright (c) 2017 Pieter Wuille
//
//  Created by Evolution Group Ltd on 12.02.2018.
//  Copyright © 2018 Evolution Group Ltd. All rights reserved.
//


import XCTest
@testable import SwiftLightning


class Bech32Test: XCTestCase {
  
  fileprivate typealias InvalidChecksum = (bech32: String, error: Bech32.DecodingError)
  fileprivate typealias ValidAddressData = (address: String, script: [UInt8])
  fileprivate typealias InvalidAddressData = (hrp: String, version: Int, programLen: Int)
  
  let bech32 = Bech32()
  let addrCoder = SegwitAddrCoder()
  
  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }
  
  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }
  
  func testInvalidAddresses() {
    let INVALID_ADDRESS = [
      "tc1qw508d6qejxtdg4y5r3zarvary0c5xw7kg3g4ty",
      "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t5",
      "BC13W508D6QEJXTDG4Y5R3ZARVARY0C5XW7KN40WF2",
      "bc1rw5uspcuh",
      "bc10w508d6qejxtdg4y5r3zarvary0c5xw7kw508d6qejxtdg4y5r3zarvary0c5xw7kw5rljs90",
      "BC1QR508D6QEJXTDG4Y5R3ZARVARYV98GJ9P",
      "tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sL5k7",
      "tb1pw508d6qejxtdg4y5r3zarqfsj6c3",
      "tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3pjxtptv",
      ]
    
    INVALID_ADDRESS.forEach { test in
      ["bc", "tb"].forEach { type in
        do {
          let _ = try addrCoder.decode(hrp: type, addr: test)
          
          XCTFail("Expected invalid address: \(test)")
        } catch {
          return
        }
      }
    }
  }
  
  func testChecksums() {
    let VALID_CHECKSUM: [String] = [
      "A12UEL5L",
      "an83characterlonghumanreadablepartthatcontainsthenumber1andtheexcludedcharactersbio1tt5tgs",
      "abcdef1qpzry9x8gf2tvdw0s3jn54khce6mua7lmqqqxw",
      "11qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqc8247j",
      "split1checkupstagehandshakeupstreamerranterredcaperred2y9e3w"
    ]
    
    do {
      try VALID_CHECKSUM.forEach { test in
        let _ = try bech32.decode(test)
      }
    } catch {
      XCTFail(error.localizedDescription)
    }
  }
  
  func testValidAddresses() {
    let VALID_BC_ADDRESSES: [String: (decoded: [UInt8], type: String)] = [
      "BC1QW508D6QEJXTDG4Y5R3ZARVARY0C5XW7KV8F3T4": (
        decoded: [
          0x00, 0x14, 0x75, 0x1e, 0x76, 0xe8, 0x19, 0x91, 0x96, 0xd4, 0x54,
          0x94, 0x1c, 0x45, 0xd1, 0xb3, 0xa3, 0x23, 0xf1, 0x43, 0x3b, 0xd6
        ],
        type: "bc"
      ),
      
      "tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sl5k7": (
        decoded: [
          0x00, 0x20, 0x18, 0x63, 0x14, 0x3c, 0x14, 0xc5, 0x16, 0x68, 0x04,
          0xbd, 0x19, 0x20, 0x33, 0x56, 0xda, 0x13, 0x6c, 0x98, 0x56, 0x78,
          0xcd, 0x4d, 0x27, 0xa1, 0xb8, 0xc6, 0x32, 0x96, 0x04, 0x90, 0x32,
          0x62
        ],
        type: "tb"
      ),
      
      "bc1pw508d6qejxtdg4y5r3zarvary0c5xw7kw508d6qejxtdg4y5r3zarvary0c5xw7k7grplx": (
        decoded: [
          0x81, 0x28, 0x75, 0x1e, 0x76, 0xe8, 0x19, 0x91, 0x96, 0xd4, 0x54,
          0x94, 0x1c, 0x45, 0xd1, 0xb3, 0xa3, 0x23, 0xf1, 0x43, 0x3b, 0xd6,
          0x75, 0x1e, 0x76, 0xe8, 0x19, 0x91, 0x96, 0xd4, 0x54, 0x94, 0x1c,
          0x45, 0xd1, 0xb3, 0xa3, 0x23, 0xf1, 0x43, 0x3b, 0xd6
        ],
        type: "bc"
      ),
      
      "BC1SW50QA3JX3S": (decoded: [0x90, 0x02, 0x75, 0x1e], type: "bc"),
      
      "bc1zw508d6qejxtdg4y5r3zarvaryvg6kdaj": (
        decoded: [
          0x82, 0x10, 0x75, 0x1e, 0x76, 0xe8, 0x19, 0x91, 0x96, 0xd4, 0x54,
          0x94, 0x1c, 0x45, 0xd1, 0xb3, 0xa3, 0x23
        ],
        type: "bc"
      ),
      
      "tb1qqqqqp399et2xygdj5xreqhjjvcmzhxw4aywxecjdzew6hylgvsesrxh6hy": (
        decoded: [
          0x00, 0x20, 0x00, 0x00, 0x00, 0xc4, 0xa5, 0xca, 0xd4, 0x62, 0x21,
          0xb2, 0xa1, 0x87, 0x90, 0x5e, 0x52, 0x66, 0x36, 0x2b, 0x99, 0xd5,
          0xe9, 0x1c, 0x6c, 0xe2, 0x4d, 0x16, 0x5d, 0xab, 0x93, 0xe8, 0x64,
          0x33
        ],
        type: "tb"
      )
    ]
    
    do {
      try VALID_BC_ADDRESSES.forEach { address, result in
        let ret = try addrCoder.decode(hrp: result.type, addr: address)
        let recreated = try addrCoder.encode(hrp: result.type, version: ret.version, program: ret.program).lowercased()
        
        XCTAssertEqual(recreated, address.lowercased())
      }
    } catch {
      XCTFail(error.localizedDescription)
    }
  }
  
  private let _validChecksum: [String] = [
    "A12UEL5L",
    "an83characterlonghumanreadablepartthatcontainsthenumber1andtheexcludedcharactersbio1tt5tgs",
    "abcdef1qpzry9x8gf2tvdw0s3jn54khce6mua7lmqqqxw",
    "11qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqc8247j",
    "split1checkupstagehandshakeupstreamerranterredcaperred2y9e3w",
    "?1ezyfcl"
  ]
  
  private let _invalidChecksum: [InvalidChecksum] = [
    (" 1nwldj5", Bech32.DecodingError.nonPrintableCharacter),
    ("\u{7f}1axkwrx", Bech32.DecodingError.nonPrintableCharacter),
    ("an84characterslonghumanreadablepartthatcontainsthenumber1andtheexcludedcharactersbio1569pvx", Bech32.DecodingError.stringLengthExceeded),
    ("pzry9x0s0muk", Bech32.DecodingError.noChecksumMarker),
    ("1pzry9x0s0muk", Bech32.DecodingError.incorrectHrpSize),
    ("x1b4n0q5v", Bech32.DecodingError.invalidCharacter),
    ("li1dgmt3", Bech32.DecodingError.incorrectChecksumSize),
    ("de1lg7wt\u{ff}", Bech32.DecodingError.nonPrintableCharacter),
    ("10a06t8", Bech32.DecodingError.incorrectHrpSize),
    ("1qzzfhee", Bech32.DecodingError.incorrectHrpSize)
  ]
  
  private let _invalidAddress: [String] = [
    "tc1qw508d6qejxtdg4y5r3zarvary0c5xw7kg3g4ty",
    "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t5",
    "BC13W508D6QEJXTDG4Y5R3ZARVARY0C5XW7KN40WF2",
    "bc1rw5uspcuh",
    "bc10w508d6qejxtdg4y5r3zarvary0c5xw7kw508d6qejxtdg4y5r3zarvary0c5xw7kw5rljs90",
    "BC1QR508D6QEJXTDG4Y5R3ZARVARYV98GJ9P",
    "tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sL5k7",
    "bc1zw508d6qejxtdg4y5r3zarvaryvqyzf3du",
    "tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3pjxtptv",
    "bc1gmk9yu"
  ]
  
  private let _validAddressData: [ValidAddressData] = [
    ("BC1QW508D6QEJXTDG4Y5R3ZARVARY0C5XW7KV8F3T4", [
      0x00, 0x14, 0x75, 0x1e, 0x76, 0xe8, 0x19, 0x91, 0x96, 0xd4, 0x54,
      0x94, 0x1c, 0x45, 0xd1, 0xb3, 0xa3, 0x23, 0xf1, 0x43, 0x3b, 0xd6
      ]),
    ("tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sl5k7", [
      0x00, 0x20, 0x18, 0x63, 0x14, 0x3c, 0x14, 0xc5, 0x16, 0x68, 0x04,
      0xbd, 0x19, 0x20, 0x33, 0x56, 0xda, 0x13, 0x6c, 0x98, 0x56, 0x78,
      0xcd, 0x4d, 0x27, 0xa1, 0xb8, 0xc6, 0x32, 0x96, 0x04, 0x90, 0x32,
      0x62
      ]),
    ("bc1pw508d6qejxtdg4y5r3zarvary0c5xw7kw508d6qejxtdg4y5r3zarvary0c5xw7k7grplx", [
      0x81, 0x28, 0x75, 0x1e, 0x76, 0xe8, 0x19, 0x91, 0x96, 0xd4, 0x54,
      0x94, 0x1c, 0x45, 0xd1, 0xb3, 0xa3, 0x23, 0xf1, 0x43, 0x3b, 0xd6,
      0x75, 0x1e, 0x76, 0xe8, 0x19, 0x91, 0x96, 0xd4, 0x54, 0x94, 0x1c,
      0x45, 0xd1, 0xb3, 0xa3, 0x23, 0xf1, 0x43, 0x3b, 0xd6
      ]),
    ("BC1SW50QA3JX3S", [
      0x90, 0x02, 0x75, 0x1e
      ]),
    ("bc1zw508d6qejxtdg4y5r3zarvaryvg6kdaj", [
      0x82, 0x10, 0x75, 0x1e, 0x76, 0xe8, 0x19, 0x91, 0x96, 0xd4, 0x54,
      0x94, 0x1c, 0x45, 0xd1, 0xb3, 0xa3, 0x23
      ]),
    ("tb1qqqqqp399et2xygdj5xreqhjjvcmzhxw4aywxecjdzew6hylgvsesrxh6hy", [
      0x00, 0x20, 0x00, 0x00, 0x00, 0xc4, 0xa5, 0xca, 0xd4, 0x62, 0x21,
      0xb2, 0xa1, 0x87, 0x90, 0x5e, 0x52, 0x66, 0x36, 0x2b, 0x99, 0xd5,
      0xe9, 0x1c, 0x6c, 0xe2, 0x4d, 0x16, 0x5d, 0xab, 0x93, 0xe8, 0x64,
      0x33
      ])
  ]
  
  private let _invalidAddressData: [InvalidAddressData] = [
    ("BC", 0, 20),
    ("bc", 0, 21),
    ("bc", 17, 32),
    ("bc", 1, 1),
    ("bc", 16, 41)
  ]
  
  func testValidChecksum() {
    for valid in _validChecksum {
      do {
        let decoded = try bech32.decode(valid)
        XCTAssertFalse(decoded.hrp.isEmpty, "Empty result for \"\(valid)\"")
        let recoded = bech32.encode(decoded.hrp, values: decoded.checksum)
        XCTAssert(valid.lowercased() == recoded.lowercased(), "Roundtrip encoding failed: \(valid) != \(recoded)")
      } catch {
        XCTFail("Error decoding \(valid): \(error.localizedDescription)")
      }
    }
  }
  
  func testInvalidChecksum() {
    for invalid in _invalidChecksum {
      let checksum = invalid.bech32
      let reason = invalid.error
      do {
        let decoded = try bech32.decode(checksum)
        XCTFail("Successfully decoded an invalid checksum \(checksum): \(decoded.checksum.hexEncodedString())")
      } catch let error as Bech32.DecodingError {
        XCTAssert(errorsEqual(error, reason), "Decoding error mismatch, got \(error.localizedDescription), expected \(reason.localizedDescription)")
      } catch {
        XCTFail("Invalid error occured: \(error.localizedDescription)")
      }
    }
  }
  
  func testValidAddress() {
    for valid in _validAddressData {
      let address = valid.address
      let script = Data(valid.script)
      var hrp = "bc"
      
      var decoded = try? addrCoder.decode(hrp: hrp, addr: address)
      
      do {
        if decoded == nil {
          hrp = "tb"
          decoded = try addrCoder.decode(hrp: hrp, addr: address)
        }
      } catch {
        XCTFail("Failed to decode \(address)")
        continue
      }
      
      let scriptPk = segwitPubKey(version: decoded!.version, program: decoded!.program)
      XCTAssert(scriptPk == script, "Decoded script mismatch: \(scriptPk.hexEncodedString()) != \(script.hexEncodedString())")
      
      do {
        let recoded = try addrCoder.encode(hrp: hrp, version: decoded!.version, program: decoded!.program)
        XCTAssertFalse(recoded.isEmpty, "Recoded string is empty for \(address)")
      } catch {
        XCTFail("Roundtrip encoding failed for \"\(address)\" with error: \(error.localizedDescription)")
      }
    }
  }
  
  func testInvalidAddress() {
    for invalid in _invalidAddress {
      do {
        let decoded = try addrCoder.decode(hrp: "bc", addr: invalid)
        XCTFail("Successfully decoded an invalid address \(invalid) for hrp \"bc\": \(decoded.program.hexEncodedString())")
      } catch {
        // OK here :)
      }
      
      do {
        let decoded = try addrCoder.decode(hrp: "tb", addr: invalid)
        XCTFail("Successfully decoded an invalid address \(invalid) for hrp \"tb\": \(decoded.program.hexEncodedString())")
      } catch {
        // OK again
      }
    }
  }
  
  func testInvalidAddressEncoding() {
    for invalid in _invalidAddressData {
      do {
        let zeroData = Data(repeating: 0x00, count: invalid.programLen)
        let wtf = try addrCoder.encode(hrp: invalid.hrp, version: invalid.version, program: zeroData)
        XCTFail("Successfully encoded zero bytes data \(wtf)")
      } catch {
        // the way it should go
      }
    }
  }
  
  func testAddressEncodingDecodingPerfomance() {
    let addressToCode = _validAddressData[0].address
    self.measure {
      do {
        for _ in 0..<10 {
          let decoded = try addrCoder.decode(hrp: "bc", addr: addressToCode)
          let _ = try addrCoder.encode(hrp: "bc", version: decoded.version, program: decoded.program)
        }
      } catch {
        XCTFail(error.localizedDescription)
        return
      }
    }
  }
  
  private func segwitPubKey(version: Int, program: Data) -> Data {
    var result = Data()
    result.append(version != 0 ? (0x80 | UInt8(version)) : 0x00)
    result.append(UInt8(program.count))
    result.append(program)
    return result
  }
  
  private func errorsEqual(_ lhs: Bech32.DecodingError, _ rhs: Bech32.DecodingError) -> Bool {
    switch lhs {
    case .checksumMismatch:
      return rhs == .checksumMismatch
    case .incorrectChecksumSize:
      return rhs == .incorrectChecksumSize
    case .incorrectHrpSize:
      return rhs == .incorrectHrpSize
    case .invalidCase:
      return rhs == .invalidCase
    case .invalidCharacter:
      return rhs == .invalidCharacter
    case .noChecksumMarker:
      return rhs == .noChecksumMarker
    case .nonUTF8String:
      return rhs == .nonUTF8String
    case .stringLengthExceeded:
      return rhs == .stringLengthExceeded
    case .nonPrintableCharacter:
      return rhs == .nonPrintableCharacter
    }
  }
  
  static var allTests = [
    ("Valid Checksum", testValidChecksum),
    ("Invalid Checksum", testInvalidChecksum),
    ("Valid Address", testValidAddress),
    ("Invalid Address", testInvalidAddress),
    ("Zero Data", testInvalidAddressEncoding),
    ("Perfomance", testAddressEncodingDecodingPerfomance)
  ]
}
