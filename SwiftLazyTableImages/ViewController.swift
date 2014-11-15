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

let kCustomRowCount = 7
let CellIdentifier = "LazyTableCell"
let PlaceholderCellIdentifier = "PlaceholderCell"

class MyTableViewCell: UITableViewCell {
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: UITableViewCellStyle.Subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ViewController: UITableViewController, UIScrollViewDelegate {
    
    var entries = [ParsedRecord]()
    
    var imageDownloadsInProgress: [NSIndexPath: ImageDownloader]!

    //MARK: Loading method
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        tableView.registerClass(MyTableViewCell.self, forCellReuseIdentifier: CellIdentifier)
        tableView.registerClass(MyTableViewCell.self, forCellReuseIdentifier: PlaceholderCellIdentifier)
        
        imageDownloadsInProgress = [NSIndexPath: ImageDownloader]()
    }
    
    //MARK: UITableView Delegate
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let count = entries.count
        
        if count == 0 {
            return kCustomRowCount
        } else {
            return count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: MyTableViewCell!
        
        var nodeCount = entries.count
        
        if nodeCount == 0 && indexPath.row == 0 {
            //placeholder cell needed
            cell = tableView.dequeueReusableCellWithIdentifier(PlaceholderCellIdentifier, forIndexPath: indexPath) as MyTableViewCell
            cell.detailTextLabel?.text = "Loading..."
        } else {
            cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier, forIndexPath: indexPath) as MyTableViewCell
            
            if nodeCount > 0 {
                var parsedRecord = entries[indexPath.row] as ParsedRecord
                cell.textLabel.text = parsedRecord.title
                cell.detailTextLabel?.text = parsedRecord.parsedDescription
                
                if parsedRecord.image == nil {
                    if tableView.dragging == false && tableView.decelerating == false {
                        //startIconDownload
                        startIconDownload(parsedRecord, forIndexPath: indexPath)
                    }
                    cell.imageView.image = UIImage(named: "Placeholder.png")
                } else {
                    cell.imageView.image = parsedRecord.image
                }
            }
        }
        return cell
    }
    
    //MARK: Image downloading methods
    func startIconDownload(parsedRecord: ParsedRecord, forIndexPath indexPath: NSIndexPath) {
        var imageDownloader: ImageDownloader? = imageDownloadsInProgress[indexPath]
        if (imageDownloader == nil) {
            imageDownloader = ImageDownloader()
            imageDownloader?.parsedRecord = parsedRecord
            imageDownloader?.completionHandler = {
                (_) in
                var cell = self.tableView.cellForRowAtIndexPath(indexPath) as MyTableViewCell
                cell.imageView.image = parsedRecord.image
                
                self.imageDownloadsInProgress.removeValueForKey(indexPath)
            }
            imageDownloadsInProgress[indexPath] = imageDownloader
            imageDownloader?.startDownload()
        }
    }
    
    func loadImageForOnScreenRows() {
        if entries.count > 0 {
            var visiblePaths = tableView.indexPathsForVisibleRows() as [NSIndexPath]
            for indexPath in visiblePaths {
                var parsedRecord = entries[indexPath.row]
                
                if parsedRecord.image == nil {
                    startIconDownload(parsedRecord, forIndexPath: indexPath)
                }
            }
        }
    }
    
    //MARK: UIScrollView methods
    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            loadImageForOnScreenRows()
        }
    }
    
    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        loadImageForOnScreenRows()
    }
    
    //MARK: Methods that take care of any termination
    func terminateAllDownloads() {
        var allDownloads = imageDownloadsInProgress.values.array
        for downloader in allDownloads {
            downloader.cancelDownload()
        }
        imageDownloadsInProgress.removeAll(keepCapacity: false)
    }
    
    deinit {
        terminateAllDownloads()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        terminateAllDownloads()
    }


}

