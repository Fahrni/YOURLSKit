# YOURLSKit

YOURLS Kit is a bit of Swift that allows you to shorten and expand links using your [YOURLS](https://yourls.org) server.

NOTE: I haven't tested any of this code. Just wrote it, compiled it, and committed it. 

I'd be happy to accept pull requests.

To shorten a link:
```        
yourls.shorten(expandedURL: "http://jerryfahrni.com/ptug/") { (link: YOURLSLink?, error: Error?) in
  if let link = link {
    print("short link ==> \(link.shortLink)")
  }
}
```

To expand a link:
```
yourls.expand(shortURL: "http://youryourlsurl.xxx/ptug/") { (link: YOURLSLink?, error: Error?) in
  if let link = link {
    print("expanded link ==> \(link.expandedLink)")
  }
}
```

[Rob Fahrni](https://fahrni.me), August 27, 2017
