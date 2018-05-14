//
//  PeerAddrTableViewCell.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-05-13.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

class PeerAddrTableViewCell: UITableViewCell {
  
  struct Constants {
    static let preferredHeight: CGFloat = 70.0
  }
  
  @IBOutlet weak var peerAddrTextField: UITextField!
  
  @IBOutlet private weak var peerAddrLabel: UILabel!
  
  func setPeerAddrLabel(withIdx index: Int) {
    peerAddrLabel.text = "Neutrino Peer Address #\(index)"
  }
  
  @IBAction func peerAddrTapped(_ sender: UITapGestureRecognizer) {
    peerAddrTextField.becomeFirstResponder()
  }
}
