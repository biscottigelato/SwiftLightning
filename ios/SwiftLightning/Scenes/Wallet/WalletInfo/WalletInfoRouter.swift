//
//  WalletInfoRouter.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-05-13.
//  Copyright (c) 2018 BiscottiGelato. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

@objc protocol WalletInfoRoutingLogic {
  func routeToPrevious()
}

protocol WalletInfoDataPassing {
  var dataStore: WalletInfoDataStore? { get }
}

class WalletInfoRouter: NSObject, WalletInfoRoutingLogic, WalletInfoDataPassing {
  weak var viewController: WalletInfoViewController?
  var dataStore: WalletInfoDataStore?
  
  // MARK: Routing
  
  func routeToPrevious() {
    //    let destinationVC = viewController! as! WalletMainViewController
    //    var destinationDS = destinationVC.router!.dataStore!
    //    passDataToWalletMain(source: dataStore!, destination: &destinationDS)
    navigateToPrevious(source: viewController!)
  }
  
  
  // MARK: Navigation
  
  func navigateToPrevious(source: WalletInfoViewController) {
    guard let navigationController = source.navigationController else {
      SLLog.assert("\(type(of: source)).navigationController = nil")
      return
    }
    navigationController.popViewController(animated: true)
  }
  
  // MARK: Passing data
  
  func passDataToWalletMain(source: WalletInfoDataStore) { }
}
