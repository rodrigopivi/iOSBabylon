import UIKit
import WebKit
import JavaScriptCore

class ViewController: UIViewController, WKUIDelegate {
    var webView: WKWebView?
    var webConfig:WKWebViewConfiguration {
        get {
                var webCfg:WKWebViewConfiguration = WKWebViewConfiguration()
                var userController:WKUserContentController = WKUserContentController()
                webCfg.userContentController = userController
            return webCfg;
        }
    }
    
    // TODO: hack for serving the assets form the /tmp/assets/ path, ios9 will solve this
    //       meanwhile its a todo to refactor this in a better way
    func copyFileToTmpForServingAsStaticAsset(filePath: String?) -> String? {
        let fileMgr = NSFileManager.defaultManager()
        let tmpPath = NSTemporaryDirectory().stringByAppendingPathComponent("assets")
        var error: NSErrorPointer = nil
        if !fileMgr.createDirectoryAtPath(tmpPath, withIntermediateDirectories: true, attributes: nil, error: error) {
            println("Couldn't create assets subdirectory. \(error)")
            return nil
        }
        let dstPath = tmpPath.stringByAppendingPathComponent(filePath!.lastPathComponent)
        if !fileMgr.fileExistsAtPath(dstPath) {
            if !fileMgr.copyItemAtPath(filePath!, toPath: dstPath, error: error) {
                println("Couldn't copy file to /tmp/assets. \(error)")
                return nil
            }
        }
        return dstPath
    }

    func jsExceptionHandler(ctx: JSContext!, val: JSValue!) {
        NSLog("%@", val);
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        webView = WKWebView (frame: self.view.frame, configuration: webConfig)
        webView!.UIDelegate = self
        // Handle exceptions
        var context = JSContext();
        context.exceptionHandler = jsExceptionHandler
        view.addSubview(webView!)
        
        // auto resize and prevent some unneeded gestures
        webView!.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
        webView!.scrollView.scrollEnabled = false;
        webView!.scrollView.panGestureRecognizer.enabled = false;
        webView!.scrollView.bounces = false;
        
        // load files
        let assetFilesToLoad = [
            "style": "css",
            "babylon.2.2": "js",
            "app": "js"
        ]
        for (fileName, fileExt) in assetFilesToLoad {
            var filePath = NSBundle.mainBundle().pathForResource(fileName, ofType: fileExt)
            filePath = copyFileToTmpForServingAsStaticAsset(filePath)
        }
    }

    func getFileContentsAsString(filePath: String) -> String {
        var script:String = String (contentsOfFile: filePath, encoding: NSUTF8StringEncoding, error: nil)!
        return script;

    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        loadHtml()
    }

    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)

        // TODO: fix this hack to load the index.html file
        var fileName:String =  String("\( NSProcessInfo.processInfo().globallyUniqueString)_index.html")

        var error:NSError?
        var tempHtmlPath:String =  NSTemporaryDirectory().stringByAppendingPathComponent(fileName)
        NSFileManager.defaultManager().removeItemAtPath(tempHtmlPath, error: &error)

        webView = nil

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func webView(webView: WKWebView, exceptionWasRaised navigation: WKNavigation!, withError error: NSError) {
        NSLog("%s. With Error %@", __FUNCTION__,error)
        showAlertWithMessage("Failed to load file with error \(error.localizedDescription)!")
    }

    func webView(webView: WKWebView, failedToParseSource navigation: WKNavigation!, withError error: NSError) {
        NSLog("%s. With Error %@", __FUNCTION__,error)
        showAlertWithMessage("Failed to load file with error \(error.localizedDescription)!")
    }

    // WKUIDelegate
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        NSLog("%s", __FUNCTION__)
    }

    func webView(webView: WKWebView, didFailNavigation navigation: WKNavigation!, withError error: NSError) {
        NSLog("%s. With Error %@", __FUNCTION__,error)
        showAlertWithMessage("Failed to load file with error \(error.localizedDescription)!")
    }


    // File Loading
    func loadHtml() {
        // NOTE: Due to a bug in webKit as of iOS 8.1.1 we CANNOT load a local resource when running on device. Once that is fixed, we can get rid of the temp copy
        let mainBundle:NSBundle = NSBundle(forClass: ViewController.self)
        var error:NSError?

        var fileName:String =  String("\( NSProcessInfo.processInfo().globallyUniqueString)_index.html")

        var tempHtmlPath:String? = NSTemporaryDirectory().stringByAppendingPathComponent(fileName)

        if let htmlPath = mainBundle.pathForResource("index", ofType: "html") {
            NSFileManager.defaultManager().copyItemAtPath(htmlPath, toPath: tempHtmlPath!, error: &error)
            if tempHtmlPath != nil {
                let requestUrl = NSURLRequest(URL: NSURL(fileURLWithPath: tempHtmlPath!)!)
                webView?.loadRequest(requestUrl)
            }
        }
        else {
           showAlertWithMessage("Could not load HTML File!")
        }

    }

    func showAlertWithMessage(message:String) {
        let alertAction:UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) { (UIAlertAction) -> Void in
            self.dismissViewControllerAnimated(true, completion: { () -> Void in

            })
        }

        let alertView:UIAlertController = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertView.addAction(alertAction)

        self.presentViewController(alertView, animated: true, completion: { () -> Void in

        })
    }


}
