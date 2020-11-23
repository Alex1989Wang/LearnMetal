//
//  AppDelegate.swift
//  LearnMetal
//
//  Created by 王江 on 2020/11/23.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    /// the app's window
    private(set) var appWindow: UIWindow!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        appWindow = UIWindow(frame: UIScreen.main.bounds)
        let casesVC = DemoCasesViewController()
        let naviVC = UINavigationController(rootViewController: casesVC)
        appWindow.rootViewController = naviVC
        appWindow.makeKeyAndVisible()
        return true
    }

}

