//
//  AppDelegate.swift
//  SwiftLightning
//
//  Created by Howard Lee on 2018-04-02.
//  Copyright © 2018 BiscottiGelato. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  static var rootViewController: RootViewController?
  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    // Override point for customization after application launch.
    SLLog.initializeLogging()
    SLLog.initializeReporting()
    
    LNServices.initialize()
    
    // Use Light style status bar across the entire app
    UIApplication.shared.statusBarStyle = .lightContent

    // Launch Root View Controller
    let storyboard = UIStoryboard(name: "Root", bundle: nil)
    guard let viewController = storyboard.instantiateViewController(withIdentifier: "RootViewController") as? RootViewController else {
      SLLog.fatal("ViewController initiated not of RootViewController Class!!")
    }

    SLLog.debug("Applciation did finish launching with options")
    AppDelegate.rootViewController = viewController

    // Launch Playground
//    let storyboard = UIStoryboard(name: "Playground", bundle: nil)
//    guard let viewController = storyboard.instantiateViewController(withIdentifier: "PlaygroundViewController") as? PlaygroundViewController else {
//      SLLog.fatal("ViewController initiated not of PlaygroundViewController Class!!")
//    }
    
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = viewController
    window?.makeKeyAndVisible()
    
    return true
  }

  func applicationWillResignActive(_ application: UIApplication) {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    SLLog.verbose("applicationWillResignActive")
  }

  func applicationDidEnterBackground(_ application: UIApplication) {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    SLLog.verbose("applicationDidEnterBackground")
  }

  func applicationWillEnterForeground(_ application: UIApplication) {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    SLLog.verbose("applicationWillEnterForeground")
    
    // This only gets triggered if from background to foreground? Did become active also gets triggered on start.
    LNManager.reconnectAllChannels()
  }

  func applicationDidBecomeActive(_ application: UIApplication) {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    SLLog.verbose("applicationDidBecomeActive")
  }

  func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    SLLog.verbose("applicationWillTerminate")
    
    LNServices.stopDaemon { _ in SLLog.debug("LND Terminating...") }
    SLLog.debug("Pending Termination Clean-up for 1s")
    sleep(1)
    SLLog.debug("Ready for Termination")
  }
  
  
  // MARK: Handle Custom URL Schemes
  
  func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    EventCentral.shared.bufferOpenEvent(on: url)
    SLLog.debug("Applciation open URL with options")
    
    // Pop to Root and then start again
    AppDelegate.rootViewController?.dismiss(animated: false) {
      AppDelegate.rootViewController?.checkWalletUnlocked()
    }
    
    return true
  }
}

