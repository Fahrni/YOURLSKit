//
//  YOURLSClient.swift
//  YOURLSKit
//
//  Created by Rob Fahrni on 8/27/17.
//  Copyright © 2017 hayseed. All rights reserved.
//

import Foundation

typealias ActionCompletionHandler = (_ link: YOURLSLink?, _ error: Error?) -> Void
typealias POSTCompletionHandler = (Data?, URLResponse?, Error?) -> Void

class YOURLSClient: NSObject {
    struct Service {
        static let endpoint = "yourls-api.php"
        static let shortAction = "shorturl"
        static let shortURL = "shorturl"
        static let expandAction = "expand"
        static let expandURL = "url"
        static let format = "json"
        static let methodPost = "POST"
    }

    private var signature: String
    private var baseURL: String

    init(yourlsSignature: String, yourlsBaseURL: String) {
        self.signature = yourlsSignature
        self.baseURL = yourlsBaseURL
    }

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
        })
    }

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
                    let expandedURL = weakSelf.getLinkFor(key: YOURLSClient.Service.expandURL, data) {
                    let link = YOURLSLink(shortLink: shortURL, expandedLink: expandedURL)
                    completionHandler(link, nil)
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

    private func createPOSTRequest(serviceURL: String, queryParameters: [String : String]) -> URLRequest? {
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
    func urlSession(_ session: URLSession,
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
