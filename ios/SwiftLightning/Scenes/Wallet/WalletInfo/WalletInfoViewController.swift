//
//  WalletInfoViewController.swift
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

protocol WalletInfoDisplayLogic: class {
  func displayRefresh(viewModel: WalletInfo.Refresh.ViewModel)
  func displayError(viewModel: WalletInfo.ErrorVM)
}

class WalletInfoViewController: SLViewController, WalletInfoDisplayLogic {
  var interactor: WalletInfoBusinessLogic?
  var router: (NSObjectProtocol & WalletInfoRoutingLogic & WalletInfoDataPassing)?

  // MARK: Object lifecycle
  
  override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
    super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    setup()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
  
  
  // MARK: Setup
  
  private func setup() {
    let viewController = self
    let interactor = WalletInfoInteractor()
    let presenter = WalletInfoPresenter()
    let router = WalletInfoRouter()
    viewController.interactor = interactor
    viewController.router = router
    interactor.presenter = presenter
    presenter.viewController = viewController
    router.viewController = viewController
    router.dataStore = interactor
  }
  
  
  // MARK: View lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let request = WalletInfo.Refresh.Request()
    interactor?.refresh(request: request)
  }
  
  
  // MARK: Refresh Wallet Info
  
  @IBOutlet weak var idPubKeyView: SLFormLabelView!
  @IBOutlet weak var nodeAliasView: SLFormLabelView!
  @IBOutlet weak var pendingChsView: SLFormCompactView!
  @IBOutlet weak var activeChsView: SLFormCompactView!
  @IBOutlet weak var peersView: SLFormCompactView!
  @IBOutlet weak var blockHeightView: SLFormCompactView!
  @IBOutlet weak var blockHashView: SLFormLabelView!
  @IBOutlet weak var bestBlockView: SLFormLabelView!
  @IBOutlet weak var syncStatusLabel: UILabel!
  
  
  func displayRefresh(viewModel: WalletInfo.Refresh.ViewModel) {
    DispatchQueue.main.sync {
      self.idPubKeyView.textLabel.text = viewModel.idPubKey
      self.nodeAliasView.textLabel.text = viewModel.alias
      self.pendingChsView.textLabel.text = viewModel.pendingChs
      self.activeChsView.textLabel.text = viewModel.activeChs
      self.peersView.textLabel.text = viewModel.numPeers
      self.blockHeightView.textLabel.text = viewModel.blockHeight
      self.blockHashView.textLabel.text = viewModel.blockHash
      self.bestBlockView.textLabel.text = viewModel.bestHdrTimestamp
      self.syncStatusLabel.text = viewModel.syncedChain
    }
  }
  
  
  // MARK: Error Display
  
  func displayError(viewModel: WalletInfo.ErrorVM) {
    let alertDialog = UIAlertController(title: viewModel.errTitle,
                                        message: viewModel.errMsg, preferredStyle: .alert).addAction(title: "OK", style: .default)
    DispatchQueue.main.async {
      self.present(alertDialog, animated: true, completion: nil)
    }
  }
  
  
  // MARK: Close Cross Tapped
  
  @IBAction func closeCrossTapped(_ sender: UIBarButtonItem) {
    router?.routeToPrevious()
  }
  
}
