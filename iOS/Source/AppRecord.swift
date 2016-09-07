import UIKit

class AppRecord {
    let appName: String
    let artist: String
    let imageURLString: String
    var appIcon: UIImage?

    init(appName: String, artist: String, imageURLString: String) {
        self.appName = appName
        self.artist = artist
        self.imageURLString = imageURLString
    }
}