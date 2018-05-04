//
//  ChTableViewCell.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-05-03.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

class ChTableViewCell: UITableViewCell {
  
  // MARK: IBOutlet

  @IBOutlet weak var canPayAmountLabel: UILabel!
  @IBOutlet weak var canRcvAmountLabel: UILabel!
  @IBOutlet weak var nodePubKeyLabel: UILabel!
  @IBOutlet weak var statusLabel: UILabel!
  
  
  struct Constants {
    static let preferredHeight: CGFloat = 80.0
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    // Initialization code
  }
  
  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    // Configure the view for the selected state
  }
  
}
