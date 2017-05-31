//
//  MovieClipHandler.swift
//  broadcastUploadExtension
//

import Foundation
import ReplayKit

class MovieClipHandler: RPBroadcastMP4ClipHandler {
    
    override func processMP4Clip(with mp4ClipURL: URL?, setupInfo: [String : NSObject]?, finished: Bool) {
        // Get the endpoint url supplied by the UI extension in the service info dictionary
        let url = URL(string: setupInfo!["endpointURL"] as! String)
        
        // Set up the request
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        
        // Upload the movie file with an upload task
        let session = URLSession.shared
        let uploadTask = session.uploadTask(with: request, fromFile: url!) { (data, response, error) in
            if (error != nil) {
                // Handle error locally
            }
            
            // Update broadcast settings if necessary
            let broadcastConfiguration = RPBroadcastConfiguration()
            broadcastConfiguration.clipDuration = 5
            
            // Tell ReplayKit that processing is complete for thie clip
            self.finishedProcessingMP4Clip(withUpdatedBroadcastConfiguration: broadcastConfiguration, error: nil)
        }
        
        uploadTask.resume()
    }
}
