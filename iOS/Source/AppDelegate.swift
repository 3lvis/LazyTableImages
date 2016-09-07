import UIKit

@UIApplicationMain
class AppDelegate: UIResponder {
    static let topPaidAppsFeed = "http://phobos.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/limit=200/json"

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
                    fatalError("Error fetching data: \(error.localizedDescription)")
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
}

extension AppDelegate: ParseOperationDelegate {
    func parseOperation(parseOperation: ParseOperation, didFinishWithAppRecords appRecords: [AppRecord], error: NSError?) {
        dispatch_async(dispatch_get_main_queue()) {
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            if let error = error {
                fatalError("Error parsing data: \(error.localizedDescription)")
            } else {
                self.rootController.appRecords = appRecords
            }
        }
    }
}