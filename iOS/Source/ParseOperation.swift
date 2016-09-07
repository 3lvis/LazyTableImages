import Foundation

protocol ParseOperationDelegate: class {
    func parseOperation(parseOperation: ParseOperation, didFinishedWithItems items: [AppRecord], error: NSError?)
}

//enum ParsedAttributes: String {
//    case feed = "feed"
//    case entry = "entry"
//
//    case id = "id"
//    case name = "im:name"
//    case image = "im:image"
//    case artist = "im:artist"
//}

class ParseOperation: NSOperation {
    weak var delegate: ParseOperationDelegate?

    let data: NSData

    var items = [AppRecord]()

    init(data: NSData) {
        self.data = data
    }

    override func main() {
        do {
            let JSON = try NSJSONSerialization.JSONObjectWithData(self.data, options: []) as! [String : AnyObject]
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

                let idEntry = entry["id"] as! [String : AnyObject]
                let appURLString = idEntry["label"] as! String
                let idEntryAttributes = idEntry["attributes"] as! [String : AnyObject]
                let id = idEntryAttributes["im:id"] as! String

                let appRecord = AppRecord(id: id, appName: appName, artist: artist, imageURLString: imageURLString!, appURLString: appURLString, appIcon: nil)
                self.items.append(appRecord)
            }

            self.delegate?.parseOperation(self, didFinishedWithItems: self.items, error: nil)
        } catch let error as NSError {
            self.delegate?.parseOperation(self, didFinishedWithItems: self.items, error: error)
        }
    }
}