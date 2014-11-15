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

class ImageDownloader: NSObject, NSURLConnectionDataDelegate {
    let kAppIconSize: CGFloat = 48
    
    var parsedRecord = ParsedRecord()
    var completionHandler: (() -> Void)?
    
    var activeDownload: NSMutableData!
    var imageConnection: NSURLConnection!
    
    func startDownload() {
        activeDownload = NSMutableData()
        
        var request = NSURLRequest(URL: NSURL(string: parsedRecord.imageURLString)!)
        
        var conn = NSURLConnection(request: request, delegate: self)
        
        imageConnection = conn
    }
    
    func cancelDownload() {
        imageConnection.cancel()
        imageConnection = nil
        activeDownload = nil
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        activeDownload.appendData(data)
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        activeDownload = nil
        imageConnection = nil
        
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        var imageIcon: UIImage = UIImage(data: activeDownload)!
        
        if imageIcon.size.width != kAppIconSize || imageIcon.size.height != kAppIconSize {
            let itemSize = CGSize(width: kAppIconSize, height: kAppIconSize)
            UIGraphicsBeginImageContextWithOptions(itemSize, false, 0.0)
            var imageRect = CGRect(x: 0, y: 0, width: itemSize.width, height: itemSize.height)
            imageIcon.drawInRect(imageRect)
            parsedRecord.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        else
        {
            parsedRecord.image = imageIcon
        }
        
        activeDownload = nil
        imageConnection = nil
        
        if completionHandler != nil {
            self.completionHandler!()
        }
        
    }
}
