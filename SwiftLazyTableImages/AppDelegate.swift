//
//  ImageDownloader.swift
//  SwiftLazyTableImages
//
//  Created by Kyle Adams on 15/11/14.
//  Copyright (c) 2014 Kyle Adams. All rights reserved.
//
//  Based on: LazyTableImages sample by Apple
//  Copyright (C) 2014 Apple Inc.

import UIKit
import Foundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, NSURLConnectionDataDelegate {

    var window: UIWindow?
    
    // the http URL used for fetching the top iOS paid apps on the App Store
    let FeedToParse = "http://www.nasa.gov/rss/dyn/image_of_the_day.rss"
    
    // the queue to run our "ParseOperation"
    var queue: NSOperationQueue!
    
    // RSS feed network connection to the App Store
    var parseFeedConnection: NSURLConnection!
    var parseFeedData: NSMutableData!


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        let urlRequest = NSURLRequest(URL: NSURL(string: FeedToParse)!)
        parseFeedConnection = NSURLConnection(request: urlRequest, delegate: self)
        
        return true
    }
    
    func handleError(error: NSError) {
        let errorMessage = error.localizedDescription
        var alertView = UIAlertView(title: "Cannot show feed",
                                    message: errorMessage,
                                    delegate: nil,
                                    cancelButtonTitle: "OK")
        
        alertView.show()
    }
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        parseFeedData = NSMutableData()
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        parseFeedData.appendData(data)
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        handleError(error)
        parseFeedConnection = nil
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        parseFeedConnection = nil
        
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        
        queue = NSOperationQueue()
        
        var parser = ParseOperation(data: parseFeedData)
        
        parser.errorHandler = {(parseError: NSError) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.handleError(parseError)
            })
        }
        
        var weakParser = parser
        
        parser.completionBlock = { () -> Void in
                // The root rootViewController is the only child of the navigation
                // controller, which is the window's rootViewController.
                if (weakParser.parsedFeedList != nil) {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        var navController: UINavigationController = self.window?.rootViewController as UINavigationController
                        var viewController: ViewController = navController.topViewController as ViewController
                        
                        viewController.entries = weakParser.parsedFeedList!
                        
                        // tell our table view to reload its data, now that parsing has completed
                        viewController.tableView.reloadData()
                    })
                }
            // we are finished with the queue and our ParseOperation
            self.queue = nil;
        }
        queue.addOperation(parser)
        parseFeedData = nil
    }

}

