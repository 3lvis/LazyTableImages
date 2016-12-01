import Foundation

protocol ParseOperationDelegate: class {
    func parseOperation(_ parseOperation: ParseOperation, didFinishWithAppRecords appRecords: [AppRecord], error: NSError?)
}

class ParseOperation: Operation {
    weak var delegate: ParseOperationDelegate?

    let data: Data

    var appRecords = [AppRecord]()

    init(data: Data) {
        self.data = data
    }

    override func main() {
        do {
            let JSON = try JSONSerialization.jsonObject(with: self.data, options: []) as! [String : AnyObject]
            let feed = JSON["feed"] as! [String : AnyObject]
            let entries = feed["entry"] as! [[String : AnyObject]]
            for entry in entries {
                let nameEntry = entry["im:name"] as! [String : AnyObject]
                let appName = nameEntry["label"] as! String

                let artistEntry = entry["im:artist"] as! [String : AnyObject]
                let artist = artistEntry["label"] as! String

                let imageEntries = entry["im:image"] as! [[String : AnyObject]]
                var imageURLString: String?
                for imageEntry in imageEntries {
                    let attributes = imageEntry["attributes"] as! [String : AnyObject]
                    let height = attributes["height"] as! String
                    if height == "100" {
                        imageURLString = imageEntry["label"] as? String
                    }
                }

                let appRecord = AppRecord(appName: appName, artist: artist, imageURLString: imageURLString!)
                self.appRecords.append(appRecord)
            }

            self.delegate?.parseOperation(self, didFinishWithAppRecords: self.appRecords, error: nil)
        } catch let error as NSError {
            self.delegate?.parseOperation(self, didFinishWithAppRecords: self.appRecords, error: error)
        }
    }
}
