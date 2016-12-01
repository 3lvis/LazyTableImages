import UIKit

class RootController: UITableViewController {
    var imageDownloadsInProgress = [IndexPath : IconDownloader]()

    var appRecords = [AppRecord]() {
        didSet {
            self.tableView.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.appRecords.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let appRecord = self.appRecords[indexPath.row]
        cell.textLabel?.text = appRecord.appName
        cell.detailTextLabel?.text = appRecord.artist
        if let icon = appRecord.appIcon {
            cell.imageView?.image = icon
        } else {
            self.startIconDownload(appRecord: appRecord, forIndexPath: indexPath)
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

    func startIconDownload(appRecord: AppRecord, forIndexPath indexPath: IndexPath) {
        guard self.imageDownloadsInProgress[indexPath] == nil else { return }

        let iconDownloader = IconDownloader(appRecord: appRecord, indexPath: indexPath)
        iconDownloader.delegate = self
        self.imageDownloadsInProgress[indexPath] = iconDownloader
        iconDownloader.startDownload()
    }

    func loadImagesForOnscreenRows() {
        guard self.appRecords.count != 0 else { return }

        let visibleIndexPaths = self.tableView.indexPathsForVisibleRows ?? [IndexPath]()
        for indexPath in visibleIndexPaths {
            let appRecord = self.appRecords[indexPath.row]
            if appRecord.appIcon == nil {
                self.startIconDownload(appRecord: appRecord, forIndexPath: indexPath)
            }
        }
    }

    override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.loadImagesForOnscreenRows()
        }
    }

    override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.loadImagesForOnscreenRows()
    }
}

extension RootController: IconDownloaderDelegate {
    func iconDownloaderDidFinishDownloadingImage(_ iconDownloader: IconDownloader, error: NSError?) {
        guard let cell = self.tableView.cellForRow(at: iconDownloader.indexPath as IndexPath) else { return }
        if let error = error {
            fatalError("Error loading thumbnails: \(error.localizedDescription)")
        } else {
            cell.imageView?.image = iconDownloader.appRecord.appIcon
        }
        self.imageDownloadsInProgress.removeValue(forKey: iconDownloader.indexPath as IndexPath)
    }
}
