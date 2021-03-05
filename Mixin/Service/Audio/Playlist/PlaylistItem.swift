import Foundation
import AVFoundation
import GRDB
import MixinServices

final class PlaylistItem {
    
    static let beginLoadingAssetNotification = Notification.Name("one.mixin.messenger.PlaylistItem.beginLoadingAsset")
    static let finishLoadingAssetNotification = Notification.Name("one.mixin.messenger.PlaylistItem.finishLoadingAsset")
    
    let id: String
    
    private(set) var metadata: Metadata
    private(set) var asset: AVURLAsset?
    private(set) var isLoadingAsset = false {
        didSet {
            if isLoadingAsset {
                notificationCenter.post(name: Self.beginLoadingAssetNotification, object: self)
            } else {
                notificationCenter.post(name: Self.finishLoadingAssetNotification, object: self)
            }
        }
    }
    
    private let notificationCenter = NotificationCenter.default
    
    convenience init(message: MessageItem) {
        if let mediaURL = message.mediaUrl, message.mediaStatus == MediaStatus.DONE.rawValue || message.mediaStatus == MediaStatus.READ.rawValue {
            let url = AttachmentContainer.url(for: .files, filename: mediaURL)
            let asset = AVURLAsset(url: url)
            let filename = message.name ?? message.mediaUrl ?? ""
            let metadata = Metadata(asset: asset, filename: filename)
            self.init(id: message.messageId, metadata: metadata, asset: asset)
        } else {
            let metadata = Metadata(image: nil, title: message.name, subtitle: nil)
            self.init(id: message.messageId, metadata: metadata, asset: nil)
        }
    }
    
    convenience init?(urlString: String) {
        guard let url = URL(string: urlString) else {
            return nil
        }
        guard let id = url.absoluteString.sha1 else {
            return nil
        }
        let asset: AVURLAsset
        if CacheableAsset.isURLCacheable(url) {
            asset = CacheableAsset(url: url)
        } else {
            asset = AVURLAsset(url: url)
        }
        let metadata = Metadata(asset: asset, filename: url.lastPathComponent)
        self.init(id: id, metadata: metadata, asset: asset)
    }
    
    private init(id: String, metadata: PlaylistItem.Metadata, asset: AVURLAsset?) {
        self.id = id
        self.metadata = metadata
        self.asset = asset
    }
    
    func downloadAttachment() {
        guard asset == nil && !isLoadingAsset else {
            return
        }
        isLoadingAsset = true
        let job = FileDownloadJob(messageId: id)
        if ConcurrentJobQueue.shared.addJob(job: job) {
            notificationCenter.addObserver(self,
                                           selector: #selector(updateAsset(_:)),
                                           name: AttachmentDownloadJob.didFinishNotification,
                                           object: job)
        }
    }
    
    @objc private func updateAsset(_ notification: Notification) {
        guard let filename = notification.userInfo?[AttachmentDownloadJob.UserInfoKey.mediaURL] as? String else {
            return
        }
        let url = AttachmentContainer.url(for: .files, filename: filename)
        let asset = AVURLAsset(url: url)
        self.metadata = Metadata(asset: asset, filename: url.lastPathComponent)
        self.asset = asset
        notificationCenter.removeObserver(self)
        isLoadingAsset = false
    }
    
}

extension PlaylistItem: TableRecord {
    
    public static let databaseTableName = Message.databaseTableName
    
}

extension PlaylistItem: Decodable, DatabaseColumnConvertible, MixinFetchableRecord {
    
    enum CodingKeys: String, CodingKey {
        case messageId = "id"
        case conversationId = "conversation_id"
        case mediaURL = "media_url"
        case name
    }
    
    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let messageId = try container.decode(String.self, forKey: .messageId)
        let name = try container.decodeIfPresent(String.self, forKey: .name)
        if let mediaURL = try container.decodeIfPresent(String.self, forKey: .mediaURL), !mediaURL.isEmpty {
            let url = AttachmentContainer.url(for: .files, filename: mediaURL)
            let asset = AVURLAsset(url: url)
            let metadata = Metadata(asset: asset, filename: name ?? url.lastPathComponent)
            self.init(id: messageId, metadata: metadata, asset: asset)
        } else {
            let metadata = Metadata(image: nil, title: name, subtitle: nil)
            self.init(id: messageId, metadata: metadata, asset: nil)
        }
        let jobId = FileDownloadJob.jobId(messageId: messageId)
        if let job = ConcurrentJobQueue.shared.findJobById(jodId: jobId) as? FileDownloadJob {
            notificationCenter.addObserver(self,
                                           selector: #selector(updateAsset(_:)),
                                           name: AttachmentDownloadJob.didFinishNotification,
                                           object: job)
            isLoadingAsset = true
        }
    }
    
}

extension PlaylistItem {
    
    final class Metadata {
        
        let image: UIImage?
        let title: String?
        let subtitle: String?
        
        init(image: UIImage?, title: String?, subtitle: String?) {
            self.image = image
            self.title = title
            self.subtitle = subtitle
        }
        
        init(asset: AVURLAsset, filename: String) {
            var image: UIImage?
            var title: String?
            var subtitle: String?
            for metadata in asset.commonMetadata {
                switch metadata.commonKey {
                case AVMetadataKey.commonKeyArtwork:
                    if let data = metadata.dataValue, let artwork = UIImage(data: data) {
                        image = artwork
                    }
                case AVMetadataKey.commonKeyTitle:
                    title = metadata.stringValue
                case AVMetadataKey.commonKeyArtist:
                    subtitle = metadata.stringValue
                default:
                    break
                }
            }
            self.image = image
            self.title = title ?? filename
            self.subtitle = subtitle ?? R.string.localizable.playlist_unknown_artist()
        }
        
    }
    
}
