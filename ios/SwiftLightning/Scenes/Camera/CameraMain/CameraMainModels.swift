//
//  CameraMainModels.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-05-02.
//  Copyright (c) 2018 BiscottiGelato. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit


enum CameraMode {
  case payment
  case channel
}

enum CameraMain {
  
  // MARK: Update
  
  enum Update {
    struct Request { }
    struct Response {
      var cameraMode: CameraMode
      var address: String?
      var addressValid: Bool?
    }
    struct ViewModel {
      var labelText: String
      var scanFrameColor: UIColor
      var validAddress: String?
    }
    struct ErrorVM {
      var errTitle: String
      var errLabel: String
    }
  }
}
