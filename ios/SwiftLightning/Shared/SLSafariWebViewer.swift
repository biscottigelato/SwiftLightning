//
//  SLSafariWebViewer.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-05-16.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit
import SafariServices

struct SLSafariWebViewer {
  
  static func display(on urlString: String, from presenter: UIViewController) {
    // This shall be directly called by IBAction, or might crash from not being Main thread
    let url = URL(string: urlString)!
    SLLog.info("Opening Safari View for \(url)")
    
    let safariViewController = SFSafariViewController(url: url)
    safariViewController.dismissButtonStyle = .done
    safariViewController.preferredBarTintColor = UIColor.spaceCadetBlue
    safariViewController.preferredControlTintColor = UIColor.normalText
    // safariViewController.modalPresentationStyle = .overCurrentContext
    presenter.present(safariViewController, animated: true, completion: nil)
  }
}
