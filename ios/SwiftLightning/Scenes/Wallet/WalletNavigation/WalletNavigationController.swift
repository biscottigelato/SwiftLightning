//
//  WalletNavigationController
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-22.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

class WalletNavigationController: UINavigationController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Remove shadow under the Nav Bar
    navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
    navigationBar.shadowImage = UIImage()
    
    // Set this as a background color for the Nav Controller
    view.backgroundColor = UIColor.spaceCadetBlue
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
}
