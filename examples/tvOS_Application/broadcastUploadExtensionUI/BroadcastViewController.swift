//
//  BroadcastViewController.swift
//  broadcastUploadExtensionUI
//

import ReplayKit

class BroadcastViewController: UIViewController {
    
    // Called when the user has finished interacting with the view controller and a broadcast stream can start
    func userDidFinishSetup() {
        // Broadcast url that will be returned to the application
        let broadcastURL = URL(string:"http://broadcastURL_example/stream1")
        
        // Service specific broadcast data example which will be supplied to the process extension during broadcast
        let userID = "user1"
        let endpointURL = "http://broadcastURL_example/stream1/upload"
        let setupInfo: [String: NSCoding & NSObjectProtocol] =  [ "userID" : userID as NSString, "endpointURL" : endpointURL as NSString ]
        
        // Set broadcast settings
        let broadcastConfiguration = RPBroadcastConfiguration()
        broadcastConfiguration.clipDuration = 5
        
        // Tell ReplayKit that the extension is finished setting up and can begin broadcasting
        self.extensionContext?.completeRequest(withBroadcast: broadcastURL!, broadcastConfiguration: broadcastConfiguration, setupInfo: setupInfo)
    }
    
    func userDidCancelSetup() {
        let error = NSError(domain: "YouAppDomain", code: -1, userInfo: nil)
        // Tell ReplayKit that the extension was cancelled by the user
        self.extensionContext?.cancelRequest(withError: error)
    }
}
