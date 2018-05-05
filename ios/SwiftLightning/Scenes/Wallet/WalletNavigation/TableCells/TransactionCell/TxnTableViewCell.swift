//
//  TxnTableViewCell.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-05-03.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

class TxnTableViewCell: UITableViewCell {
  
  // MARK: IBOutlet
  
  @IBOutlet weak var payTypeImageView: UIImageView!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var statusLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  @IBOutlet weak var amountLabel: UILabel!
  @IBOutlet weak var feeLabel: UILabel!
  
  
  struct Constants {
    static let preferredHeight: CGFloat = 64.0
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
