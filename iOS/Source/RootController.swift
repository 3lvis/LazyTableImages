import UIKit

class RootController: UITableViewController {
    var imageDownloadsInProgress = [NSIndexPath : IconDownloader]()

    var appRecords = [AppRecord]() {
        didSet {
            self.tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.appRecords.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
        let appRecord = self.appRecords[indexPath.row]
        cell.textLabel?.text = appRecord.appName
        cell.detailTextLabel?.text = appRecord.artist
        if let icon = appRecord.appIcon {
            cell.imageView?.image = icon
        } else {
            if self.tableView.dragging == false && self.tableView.decelerating == false {
                self.startIconDownload(appRecord: appRecord, forIndexPath: indexPath)
            }
            cell.imageView?.image = UIImage(named: "placeholder")
        }

        return cell
    }

    func terminateAllDownloads() {
        let allDownloads = Array(self.imageDownloadsInProgress.values)
        allDownloads.forEach { $0.cancelDownload() }
        self.imageDownloadsInProgress.removeAll()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        self.terminateAllDownloads()
    }

    func startIconDownload(appRecord appRecord: AppRecord, forIndexPath indexPath: NSIndexPath) {
        guard self.imageDownloadsInProgress[indexPath] == nil else { return }

        let iconDownloader = IconDownloader(appRecord: appRecord, indexPath: indexPath)
        iconDownloader.delegate = self
        self.imageDownloadsInProgress[indexPath] = iconDownloader
        iconDownloader.startDownload()
    }

    func loadImagesForOnscreenRows() {
        guard self.appRecords.count != 0 else { return }

        let visibleIndexPaths = self.tableView.indexPathsForVisibleRows ?? [NSIndexPath]()
        for indexPath in visibleIndexPaths {
            let appRecord = self.appRecords[indexPath.row]
            if appRecord.appIcon == nil {
                self.startIconDownload(appRecord: appRecord, forIndexPath: indexPath)
            }
        }
    }

    override func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.loadImagesForOnscreenRows()
        }
    }

    override func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.loadImagesForOnscreenRows()
    }
}

extension RootController: IconDownloaderDelegate {
    func iconDownloader(iconDownloader: IconDownloader, didFinishedDownloadingImage image: UIImage?, forAppRecord appRecord: AppRecord?, error: NSError?) {
        guard let cell = self.tableView.cellForRowAtIndexPath(iconDownloader.indexPath) else { return }
        if let error = error {
            fatalError("Error loading thumbnails: \(error.localizedDescription)")
        } else if let image = image {
            var appRecord = self.appRecords[iconDownloader.indexPath.row]
            appRecord.appIcon = image
            self.appRecords[iconDownloader.indexPath.row] = appRecord
            cell.imageView?.image = image
        } else {
            fatalError("No error or image")
        }
        self.imageDownloadsInProgress.removeValueForKey(iconDownloader.indexPath)
    }
}