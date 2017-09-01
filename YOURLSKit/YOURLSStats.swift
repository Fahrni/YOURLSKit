//
//  YOURLSStats.swift
//  YOURLSKit
//
//  Created by Rob Fahrni on 9/1/17.
//  Copyright © 2017 hayseed. All rights reserved.
//

import Foundation

public struct YOURLSStats {
    public var totalLinks: Int
    public var totalClicks: Int
}

/**
 Helper function to parse YOURLS Stats JSON into a YOURLSStats struct

 - parameter data: A Data value containing the results of a YOURLS stats call
 - returns: An instance of YOURLSStats or nil
 */
func statsFromData(_ data: Data) -> YOURLSStats? {
    do {
        let result = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
        guard let statsJson = result[YOURLSClient.Service.stats] as? NSDictionary,
            let links = statsJson["total_links"] as? String,
            let clicks = statsJson["total_clicks"] as? String,
            let l = Int(links),
            let c = Int(clicks) else {
            NSLog("Parsing failed to find 'stats' dictionary")
            return nil
        }
        return YOURLSStats(totalLinks: l, totalClicks: c)
    } catch let error as NSError {
        NSLog("Parsing stats data object failed: \(error)")
        return nil
    }
}
