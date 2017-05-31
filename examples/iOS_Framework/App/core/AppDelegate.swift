//
//  AppDelegate.swift
//  App
//

import UIKit
import FrameworkExample

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func applicationDidFinishLaunching(_ application: UIApplication) {
        print(MyClass().doIt())
    }
}
