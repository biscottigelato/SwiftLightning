//
//  MnemonicConfirmViewController.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-19.
//  Copyright (c) 2018 BiscottiGelato. All rights reserved.
//
//  This file was generated by the Clean Swift Xcode Templates so
//  you can apply clean architecture to your iOS and Mac projects,
//  see http://clean-swift.com
//

import UIKit

protocol MnemonicConfirmDisplayLogic: class {
  
  func displayGenRandomIndices(viewModel: MnemonicConfirm.GenRandomIndices.ViewModel)
  func displayCheckSeedWords(viewModel: MnemonicConfirm.CheckSeedWords.ViewModel)
  func displayConfirmSeedWords()
  func displayConfirmSeedWordsFailure(viewModel: MnemonicConfirm.ConfirmSeedWords.ViewModel)
}


class MnemonicConfirmViewController: SLViewController, MnemonicConfirmDisplayLogic, UITextFieldDelegate {
  
  var interactor: MnemonicConfirmBusinessLogic?
  var router: (NSObjectProtocol & MnemonicConfirmRoutingLogic & MnemonicConfirmDataPassing)?

  
  // MARK: Common IBOutlets
  
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var confirmField1: SLSeedField!
  @IBOutlet weak var confirmField2: SLSeedField!
  @IBOutlet weak var confirmField3: SLSeedField!
  
  
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
    let interactor = MnemonicConfirmInteractor()
    let presenter = MnemonicConfirmPresenter()
    let router = MnemonicConfirmRouter()
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
    keyboardScrollView = scrollView  // Hook the keyboard scroll adjust to the SLVC superclass
    
    confirmField1.textField.addTarget(self, action: #selector(checkSeedWords), for: UIControlEvents.editingChanged)
    confirmField2.textField.addTarget(self, action: #selector(checkSeedWords), for: UIControlEvents.editingChanged)
    confirmField3.textField.addTarget(self, action: #selector(checkSeedWords), for: UIControlEvents.editingChanged)
    
    confirmField1.textField.delegate = self
    confirmField2.textField.delegate = self
    confirmField3.textField.delegate = self
    
    confirmField3.textField.returnKeyType = .done
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    // Prevent phone from sleeping
    UIApplication.shared.isIdleTimerDisabled = true
    
    let genIndicesRequest = MnemonicConfirm.GenRandomIndices.Request(numToGen: 3)
    interactor?.genRandomIndices(request: genIndicesRequest)
    
    checkSeedWords()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    confirmField1.textField.becomeFirstResponder()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    view.endEditing(true)
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    
    // Allow phone to sleep
    UIApplication.shared.isIdleTimerDisabled = false
  }
  
  // MARK: Text Fields
  
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    textField.resignFirstResponder()
    
    switch textField {
    case confirmField1.textField:
      confirmField2.textField.becomeFirstResponder()
    case confirmField2.textField:
      confirmField3.textField.becomeFirstResponder()
    case confirmField3.textField:
      if confirmButton.isEnabled {
        confirmTapped(confirmButton)
      }
    default:
      break
    }
    return true
  }
  
  
  // MARK: Generate Random Indices

  func displayGenRandomIndices(viewModel: MnemonicConfirm.GenRandomIndices.ViewModel) {
    confirmField1.numberLabel.text = viewModel.labelTexts[0]
    confirmField2.numberLabel.text = viewModel.labelTexts[1]
    confirmField3.numberLabel.text = viewModel.labelTexts[2]
  }
  
  
  // MARK: Verify Seed Words

  @IBOutlet weak var confirmButton: SLBarButton!
  
  @objc private func checkSeedWords() {
    let request = MnemonicConfirm.CheckSeedWords.Request(seedWords: [confirmField1.textField.text ?? "",
                                                                     confirmField2.textField.text ?? "",
                                                                     confirmField3.textField.text ?? ""])
    interactor?.checkSeedWords(request: request)
  }
  
  func displayCheckSeedWords(viewModel: MnemonicConfirm.CheckSeedWords.ViewModel) {
    
    DispatchQueue.main.async {
      self.confirmField1.checkLabel.isHidden = viewModel.checkmarksHidden[0]
      self.confirmField2.checkLabel.isHidden = viewModel.checkmarksHidden[1]
      self.confirmField3.checkLabel.isHidden = viewModel.checkmarksHidden[2]
      
      self.confirmButton.setTitle(viewModel.confirmButtonText, for: .normal)
      self.confirmButton.setTitleColor(viewModel.confirmButtonTextColor, for: .normal)
      self.confirmButton.backgroundColor = viewModel.confirmButtonColor
      self.confirmButton.shadowColor = viewModel.confirmButtonShadowColor
      self.confirmButton.isEnabled = viewModel.confirmButtonEnable
    }
  }
  
  
  // MARK: Confirm
  
  @IBAction func confirmTapped(_ sender: SLBarButton) {
    let request = MnemonicConfirm.ConfirmSeedWords.Request(seedWords: [confirmField1.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                                                                       confirmField2.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
                                                                       confirmField3.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""])
    interactor?.confirmSeedWords(request: request)
  }
  
  func displayConfirmSeedWords() {
    router?.routeToWalletThruRoot()
  }
  
  func displayConfirmSeedWordsFailure(viewModel: MnemonicConfirm.ConfirmSeedWords.ViewModel) {
    let alertDialog = UIAlertController(title: viewModel.errorTitle, message: viewModel.errorMsg, preferredStyle: .alert).addAction(title: "OK", style: .default)
    DispatchQueue.main.async {
      self.present(alertDialog, animated: true, completion: nil)
    }
  }
  
  
  // MARK: Back
  
  @IBAction func backTapped(_ sender: SLIcon30Button) {
    router?.routeToMnemonicDisplay()
  }
  
}
