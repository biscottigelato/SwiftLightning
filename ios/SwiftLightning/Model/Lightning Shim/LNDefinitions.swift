//
//  LNDefinitions.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-17.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import Foundation

struct LNConstants {
  static let cipherSeedMnemonicWordCount = 24
  static let walletPasswordMinLength = 6
}


enum LNError: Error {
  
  // Generate Seed
  case GenerateSeedErrorSync(String)
  case GenerateSeedFailedAsync(String)
  
  // Create Wallet
  case CreateWalletInvalidCipherSeedSync
  case CreateWalletInvalidPasswordSync
  case CreateWalletErrorSync(String)
  case CreateWalletFailedAsync(String)
  
  // Unlock Wallet
  case UnlockWalletInvalidPasswordSync
  case UnlockWalletErrorSync(String)
  case UnlockWalletFailedSAsync(String)
  
  // Get Info
  case GetInfoErrorSync(String)
  case GetInfoFailedAsync(String)
}
