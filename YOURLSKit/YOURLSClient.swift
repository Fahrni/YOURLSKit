//
//  YOURLSClient.swift
//  YOURLSKit
//
//  Created by Rob Fahrni on 8/27/17.
//  Copyright © 2017 hayseed. All rights reserved.
//

import Foundation

public typealias ActionCompletionHandler = (_ link: YOURLSLink?, _ error: Error?) -> Void
public typealias StatsCompletionHandler = (_ stats: YOURLSStats?, _ error: Error?) -> Void
typealias POSTCompletionHandler = (Data?, URLResponse?, Error?) -> Void

public class YOURLSClient: NSObject {
    struct Service {
        static let yourlsError = "yourlskit.error"
        static let endpoint = "yourls-api.php"
        static let shortAction = "shorturl"
        static let shortURL = "shorturl"
        static let expandAction = "expand"
        static let longURL = "longurl"
        static let stats = "stats"
        static let format = "json"
        static let statusCode = "statusCode"
        static let message = "message"
        static let methodPost = "POST"
    }

    private var signature: String
    private var baseURL: String

    public init(yourlsSignature: String, yourlsBaseURL: String) {
        self.signature = yourlsSignature
        self.baseURL = yourlsBaseURL
    }

    /**
     Shorten a given URL String

     Given a long URL, like https://www.apple.com, this method will call your YOURLS server
     to get a short version.

     - parameter expandedURL: The long URL to shorten. E.G. https://www.apple.com
     - parameter completionHandler: A closure that receives either a YOURLSLink or an Error. Expect
     one parameter to be valid at all times.
     */
    open func shorten(expandedURL: String, completionHandler: @escaping ActionCompletionHandler) {
        let URLParameters =  [
            "action": YOURLSClient.Service.shortAction,
            "url": expandedURL,
            "format": YOURLSClient.Service.format,
            "signature": signature,
        ]
        POST(queryParameters: URLParameters,
             completionHandler: { [weak self] (data: Data?, response: URLResponse?, error: Error?) -> Void in
                if error != nil {
                    completionHandler(nil, error)
                    return
                }
                if let weakSelf = self,
                    let data = data,
                    let shortURL = weakSelf.getLinkFor(key: YOURLSClient.Service.shortURL, data) {
                    let link = YOURLSLink(shortLink: shortURL, expandedLink: expandedURL)
                    completionHandler(link, nil)
                }
                if let response = response {
                    let error = YOURLSError(urlResponse: response)
                    completionHandler(nil, error)
                }
        })
    }

    /**
     Expand a given URL String

     Given a short URL, like https://youryourls.xyz/1 , this method will call your YOURLS server
     to get the original long version.

     - parameter expandedURL: The short URL to expand. E.G. https://youryourls.xyz/1
     - parameter completionHandler: A closure that receives either a YOURLSLink or an Error. Expect
     one parameter to be valid at all times.
     */
    open func expand(shortURL: String, completionHandler: @escaping ActionCompletionHandler) {
        let URLParameters =  [
            "action": YOURLSClient.Service.expandAction,
            "shorturl": shortURL,
            "format": YOURLSClient.Service.format,
            "signature": signature,
        ]
        POST(queryParameters: URLParameters,
             completionHandler: { [weak self] (data: Data?, response: URLResponse?, error: Error?) -> Void in
                if error != nil {
                    completionHandler(nil, error)
                    return
                }
                if let weakSelf = self,
                    let data = data,
                    let expandedURL = weakSelf.getLinkFor(key: YOURLSClient.Service.longURL, data) {
                    let link = YOURLSLink(shortLink: shortURL, expandedLink: expandedURL)
                    completionHandler(link, nil)
                }
                if let response = response {
                    let error = YOURLSError(urlResponse: response)
                    completionHandler(nil, error)
                }
        })
    }

    /**
     Calls your YOURLS server to retrieve basic stats.

     Returns the total number of links on your server and the total number of clicks of those links.

     - parameter completionHandler: A closure that will receive a YOURLSStats or an Error. Expect
     on parameter to be valid at all times.
     */
    open func stats(completionHandler: @escaping StatsCompletionHandler) {
        let URLParameters =  [
            "action": YOURLSClient.Service.stats,
            "format": YOURLSClient.Service.format,
            "signature": signature,
            ]
        POST(queryParameters: URLParameters,
             completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                if error != nil {
                    completionHandler(nil, error)
                    return
                }
                if let data = data {
                    if let stats = statsFromData(data) {
                        completionHandler(stats, nil)
                        return
                    }
                    if let error = errorFromData(data) {
                        completionHandler(nil, error)
                    }
                }
                if let response = response {
                    let error = YOURLSError(urlResponse: response)
                    completionHandler(nil, error)
                }
        })
    }

    // MARK: - Private Methods

    private func POST(queryParameters: [String : String],
                      completionHandler: @escaping POSTCompletionHandler) {
        let serviceURL = baseURL+YOURLSClient.Service.endpoint
        guard let request = createPOSTRequest(serviceURL: serviceURL, queryParameters: queryParameters) else {
            completionHandler(nil, nil, nil)
            return
        }
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        let task = session.dataTask(with: request, completionHandler: completionHandler)
        task.resume()
        session.finishTasksAndInvalidate()
    }

    private func createPOSTRequest(serviceURL: String,
                                   queryParameters: [String : String]) -> URLRequest? {
        guard var URL = URL(string: serviceURL) else {
            return nil
        }
        URL = URL.appendingQueryParameters(queryParameters)
        var request = URLRequest(url: URL)
        request.httpMethod = YOURLSClient.Service.methodPost
        return request
    }

    private func getLinkFor(key: String, _ result: Data) -> String? {
        do {
            let result = try JSONSerialization.jsonObject(with: result, options: JSONSerialization.ReadingOptions.allowFragments) as! NSDictionary
            let linkString = result[key] as? String
            return linkString
        } catch let error as NSError {
            print("ERROR = \(error)")
            return nil
        }
    }
}

extension YOURLSClient: URLSessionDelegate {
    public func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Swift.Void) {
        completionHandler(.useCredential, URLCredential(trust: challenge.protectionSpace.serverTrust!))
    }
}


protocol URLQueryParameterStringConvertible {
    var queryParameters: String {get}
}

extension Dictionary : URLQueryParameterStringConvertible {
    var queryParameters: String {
        var parts: [String] = []
        for (key, value) in self {
            let part = String(format: "%@=%@",
                              String(describing: key).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!,
                              String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)
            parts.append(part as String)
        }
        return parts.joined(separator: "&")
    }

}

extension URL {
    func appendingQueryParameters(_ parametersDictionary : Dictionary<String, String>) -> URL {
        let URLString : String = String(format: "%@?%@", self.absoluteString, parametersDictionary.queryParameters)
        return URL(string: URLString)!
    }
}
