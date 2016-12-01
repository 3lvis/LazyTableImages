import UIKit

@UIApplicationMain
class AppDelegate: UIResponder {
    static let topPaidAppsFeed = "http://phobos.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/toppaidapplications/limit=200/json"

    var window: UIWindow?
    var rootController = RootController()
    let queue = OperationQueue()
}

extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = self.window else { fatalError("Window not found") }

        let navigationController = UINavigationController(rootViewController: self.rootController)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        self.fetchData()

        return true
    }

    func fetchData() {
        let request = URLRequest(url: URL(string: AppDelegate.topPaidAppsFeed)!)
        let sessionTask = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            if let error = error {
                OperationQueue.main.addOperation {
                    UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    fatalError("Error fetching data: \(error.localizedDescription)")
                }
            } else if let data = data {
                let parseOperation = ParseOperation(data: data)
                parseOperation.delegate = self
                self.queue.addOperation(parseOperation)
            } else {
                fatalError("No error or data")
            }
        }) 

        sessionTask.resume()

        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
}

extension AppDelegate: ParseOperationDelegate {
    func parseOperation(_ parseOperation: ParseOperation, didFinishWithAppRecords appRecords: [AppRecord], error: NSError?) {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            if let error = error {
                fatalError("Error parsing data: \(error.localizedDescription)")
            } else {
                self.rootController.appRecords = appRecords
            }
        }
    }
}
