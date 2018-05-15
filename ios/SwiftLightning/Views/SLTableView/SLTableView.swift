//
//  SLTableView.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-05-14.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@IBDesignable class SLTableView: UITableView {
  var maxHeight: CGFloat = UIScreen.main.bounds.size.height
  
  override var intrinsicContentSize: CGSize {
    
    let height = min((contentSize.height + contentInset.top + contentInset.bottom), maxHeight)
    return CGSize(width: (contentInset.left + contentInset.right + contentSize.width), height: height)
  }

}
