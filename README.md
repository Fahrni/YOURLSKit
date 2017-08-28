# YOURLSKit

YOURLS Kit is a bit of Swift that allows you to shorten and expand links using your [YOURLS](https://yourls.org) server.

I'd be happy to accept pull requests.

To create an instance:
```swift
let yourls = YOURLSClient(yourlsSignature: "your_yourls_signature", yourlsBaseUrl: "http://youryourlsurl.xxx/")
```

To shorten a link:
```swift        
yourls.shorten(expandedURL: "http://jerryfahrni.com/ptug/") { (link: YOURLSLink?, error: Error?) in
  if let link = link {
    print("short link ==> \(link.shortLink)")
  }
}
```

To expand a link:
```swift
yourls.expand(shortURL: "http://youryourlsurl.xxx/ptug/") { (link: YOURLSLink?, error: Error?) in
  if let link = link {
    print("expanded link ==> \(link.expandedLink)")
  }
}
```

[Rob Fahrni](https://fahrni.me), August 27, 2017
