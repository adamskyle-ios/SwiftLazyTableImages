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

class ParseOperation: NSOperation, NSXMLParserDelegate {
    //public api
    var parsedFeedList: [ParsedRecord]!
    var errorHandler: ((error: NSError) -> Void)!
    
    //string constants for xml feed
    let kIDStr = "id"
    let kNameStr   = "title"
    let kImageStr  = "enclosure"
    let kImageValueStr = "url"
    let kDescriptionStr = "description"
    let kEntryStr  = "item"
    
    //private
    var dataToParse: NSData
    var workingArray: [ParsedRecord]!
    var workingEntry: ParsedRecord!  // the current app record or XML entry being parsed
    var workingPropertyString: String!
    var workingImageURL: String!
    var elementsToParse: [String]
    var storingCharacterData: Bool!
    
    var storingImageData: Bool!
    
    init(data: NSData) {
        self.dataToParse = data
        self.elementsToParse = [kIDStr, kNameStr, kImageStr, kDescriptionStr, kEntryStr]
        super.init()
    }
    
    override func main() {
        // The default implemetation of the -start method sets up an autorelease pool
        // just before invoking -main however it does NOT setup an excption handler
        // before invoking -main.  If an exception is thrown here, the app will be
        // terminated.
        
        workingArray = [ParsedRecord]()
        workingPropertyString = String()
        workingImageURL = String()
        
        // It's also possible to have NSXMLParser download the data, by passing it a URL, but this is not
        // desirable because it gives less control over the network, particularly in responding to
        // connection errors.
        //
        var parser = NSXMLParser(data: dataToParse)
        parser.delegate = self
        parser.parse()
        
        if (!cancelled)
        {
            // Set ParsedRecordList to the result of our parsing
            parsedFeedList = workingArray
        }
        
        workingArray = nil
        workingPropertyString = nil
        //dataToParse = nil
    }
    
    func parser(parser: NSXMLParser!, didStartElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!, attributes attributeDict: [NSObject : AnyObject]!) {
        if elementName == kEntryStr {
            workingEntry = ParsedRecord()
        }
        storingCharacterData = contains(elementsToParse, elementName)
        
        if (elementName == kImageStr) {
            if let urlString = attributeDict[kImageValueStr] as? String {
                workingImageURL = urlString
            }
        }
    }
    
    func parser(parser: NSXMLParser!, didEndElement elementName: String!, namespaceURI: String!, qualifiedName qName: String!) {
        if workingEntry != nil {
            if (storingCharacterData == true) {
                var trimmedString = workingPropertyString.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                workingPropertyString = ""
                
                if elementName == kIDStr {
                    //this feed has no need for id handling
                } else if elementName == kNameStr {
                    workingEntry.title = trimmedString
                } else if elementName == kImageStr {
                    workingEntry.imageURLString = workingImageURL
                    //reset the image url string
                    workingImageURL = ""
                } else if elementName == kDescriptionStr {
                    workingEntry.parsedDescription = trimmedString
                }
                
            } else if elementName == kEntryStr {
                workingArray.append(workingEntry)
                workingEntry = nil
            }
        }
    }
    
    func parser(parser: NSXMLParser!, foundCharacters string: String!) {
        if storingCharacterData == true
        {
            workingPropertyString? += string
        }
    }
    
    func parser(parser: NSXMLParser!, parseErrorOccurred parseError: NSError!) {
        if errorHandler != nil {
            errorHandler(error: parseError)
        }
    }
    
}
