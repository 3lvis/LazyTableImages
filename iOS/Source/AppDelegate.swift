import UIKit

@UIApplicationMain
class AppDelegate: UIResponder {
    static let topPaidAppsFeed = "http://phobos.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/limit=75/json"

    var window: UIWindow?
    var rootController = RootController()
    let queue = NSOperationQueue()
}

extension AppDelegate: UIApplicationDelegate {
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        guard let window = self.window else { fatalError("Window not found") }

        let navigationController = UINavigationController(rootViewController: self.rootController)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        self.fetchData()

        return true
    }

    func fetchData() {
        let request = NSURLRequest(URL: NSURL(string: AppDelegate.topPaidAppsFeed)!)
        let sessionTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            if let error = error {
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    if error.code == NSURLErrorAppTransportSecurityRequiresSecureConnection {
                        // If you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                        // then your Info.plist has not been properly configured to match the target server.
                        fatalError()
                    } else {
                        self.handleError(error)
                    }
                }
            } else if let data = data {
                let parseOperation = ParseOperation(data: data)
                parseOperation.delegate = self
                self.queue.addOperation(parseOperation)
            } else {
                fatalError("No error or data")
            }
        }

        sessionTask.resume()

        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
    }

    func handleError(error: NSError) {
        let alert = UIAlertController(title: "Cannot show top paid apps", message: error.localizedDescription, preferredStyle: .ActionSheet)
        let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(OKAction)
        self.window?.rootViewController?.presentViewController(alert, animated: true, completion: nil)
    }
}

extension AppDelegate: ParseOperationDelegate {
    func parseOperation(parseOperation: ParseOperation, didFinishedWithItems items: [AppRecord], error: NSError?) {
        dispatch_async(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if let error = error {
                self.handleError(error)
            } else {
                self.rootController.entries = items
            }
        }
    }
}