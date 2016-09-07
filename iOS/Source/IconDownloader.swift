import Foundation
import UIKit

protocol IconDownloaderDelegate: class {
    func iconDownloader(iconDownloader: IconDownloader, didFinishedDownloadingImage image: UIImage?, forAppRecord appRecord: AppRecord?, error: NSError?)
}

class IconDownloader {
    static let iconSize = CGFloat(48)

    weak var delegate: IconDownloaderDelegate?

    var appRecord: AppRecord
    var indexPath: NSIndexPath
    var sessionTask: NSURLSessionDataTask?

    init(appRecord: AppRecord, indexPath: NSIndexPath) {
        self.appRecord = appRecord
        self.indexPath = indexPath
    }

    func startDownload() {
        let request = NSURLRequest(URL: NSURL(string: self.appRecord.imageURLString)!)
        self.sessionTask = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            if let error = error {
                if error.code == NSURLErrorAppTransportSecurityRequiresSecureConnection {
                    // If you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                    // then your Info.plist has not been properly configured to match the target server.
                    fatalError()
                } else {
                    self.delegate?.iconDownloader(self, didFinishedDownloadingImage: nil, forAppRecord: nil, error: error)
                }
            } else {
                NSOperationQueue.mainQueue().addOperationWithBlock {
                    guard let data = data else { return }
                    guard let image = UIImage(data: data) else { return }
                    if image.size.width == IconDownloader.iconSize && image.size.height == IconDownloader.iconSize {
                        let itemSize = CGSize(width: IconDownloader.iconSize, height: IconDownloader.iconSize)
                        UIGraphicsBeginImageContextWithOptions(itemSize, false, 0)
                        let imageRect = CGRect(x: 0, y: 0, width: itemSize.width, height: itemSize.height)
                        image.drawInRect(imageRect)
                        self.appRecord.appIcon = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                    } else {
                        self.appRecord.appIcon = image
                    }

                    self.delegate?.iconDownloader(self, didFinishedDownloadingImage: image, forAppRecord: self.appRecord, error: nil)
                }
            }
        }

        self.sessionTask?.resume()
    }

    func cancelDownload() {
        self.sessionTask?.cancel()
    }
}