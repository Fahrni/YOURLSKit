//
//  YOURLSError.swift
//  YOURLSKit
//
//  Created by Rob Fahrni on 9/13/17.
//  Copyright © 2017 hayseed. All rights reserved.
//

import Foundation

protocol YOURLSErrorProtocol: Error {
    var localizedTitle: String { get }
    var localizedDescription: String { get }
    var code: Int { get }
}

struct YOURLSError: YOURLSErrorProtocol {
    var localizedTitle: String
    var localizedDescription: String
    var code: Int

    init(urlResponse: URLResponse) {
        if let response = urlResponse as? HTTPURLResponse {
            self.localizedTitle = NSLocalizedString("Error", comment: "")
            self.localizedDescription = HTTPURLResponse.localizedString(forStatusCode: response.statusCode)
            self.code = response.statusCode
        } else {
            self.localizedTitle = NSLocalizedString("Error", comment: "")
            self.localizedDescription = NSLocalizedString("A network error occured.", comment: "")
            self.code = -99
        }
    }
}

/**
 Helper function to parse YOURLS return values for errors

 - parameter data: A Data value containing the results of a YOURLS stats call
 - returns: An instance of YOURLSStats or nil
 */
func errorFromData(_ data: Data) -> Error? {
    do {
        let result = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
        guard let statusCode = result[YOURLSClient.Service.statusCode] as? Int,
            let message = result[YOURLSClient.Service.message] as? String else {
                NSLog("Parsing failed to get status code or message")
                return nil
        }
        let userInfo = ["message": message]
        let error = NSError(domain: YOURLSClient.Service.yourlsError, code: statusCode, userInfo: userInfo)
        return error
    } catch let error as NSError {
        NSLog("Parsing stats data object failed: \(error)")
        return nil
    }
}

func errorFromResponse(urlResponse: URLResponse) {

}
