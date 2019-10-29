import Foundation
import UIKit

protocol IconDownloaderDelegate: class {
    func iconDownloaderDidFinishDownloadingImage(_ iconDownloader: IconDownloader, error: NSError?)
}

class IconDownloader {
    static let iconSize = CGFloat(48)

    weak var delegate: IconDownloaderDelegate?

    var appRecord: AppRecord
    var indexPath: IndexPath
    var sessionTask: URLSessionDataTask?

    init(appRecord: AppRecord, indexPath: IndexPath) {
        self.appRecord = appRecord
        self.indexPath = indexPath
    }

    func startDownload() {
        let request = URLRequest(url: URL(string: self.appRecord.imageURLString)!)
        self.sessionTask = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            if let error = error {
                if (error as NSError).code == NSURLErrorAppTransportSecurityRequiresSecureConnection {
                    // If you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
                    // then your Info.plist has not been properly configured to match the target server.
                    fatalError()
                } else {
                    self.delegate?.iconDownloaderDidFinishDownloadingImage(self, error: error as NSError?)
                }
            } else {
                OperationQueue.main.addOperation {
                    guard let data = data else { return }
                    guard let image = UIImage(data: data) else { return }
                    if image.size.width == IconDownloader.iconSize && image.size.height == IconDownloader.iconSize {
                        let itemSize = CGSize(width: IconDownloader.iconSize, height: IconDownloader.iconSize)
                        UIGraphicsBeginImageContextWithOptions(itemSize, false, 0)
                        let imageRect = CGRect(x: 0, y: 0, width: itemSize.width, height: itemSize.height)
                        image.draw(in: imageRect)
                        self.appRecord.appIcon = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                    } else {
                        self.appRecord.appIcon = image
                    }

                    self.delegate?.iconDownloaderDidFinishDownloadingImage(self, error: nil)
                }
            }
        }) 

        self.sessionTask?.resume()
    }

    func cancelDownload() {
        self.sessionTask?.cancel()
    }
}
