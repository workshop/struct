#if PLATFORM_IOS
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func applicationDidFinishLaunching(_ application: UIApplication) {
        print("Application did finish launching")
    }
}
#elseif PLATFORM_MAC
import AppKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
}

#endif
