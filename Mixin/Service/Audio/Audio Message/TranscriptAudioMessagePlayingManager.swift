import Foundation
import MixinServices

protocol TranscriptAudioMessagePlayingManagerDelegate: AnyObject {
    func transcriptAudioMessagePlayingManager(_ manager: TranscriptAudioMessagePlayingManager, playableMessageNextTo message: MessageItem) -> MessageItem?
}

class TranscriptAudioMessagePlayingManager: AudioMessagePlayingManager {
    
    let transcriptMessageId: String
    
    weak var delegate: TranscriptAudioMessagePlayingManagerDelegate?
    
    init(transcriptMessageId: String) {
        self.transcriptMessageId = transcriptMessageId
    }
    
    override func playableMessage(nextTo message: MessageItem) -> MessageItem? {
        return delegate?.transcriptAudioMessagePlayingManager(self, playableMessageNextTo: message)
    }
    
    override func preloadAudio(nextTo message: MessageItem) {
        guard let next = delegate?.transcriptAudioMessagePlayingManager(self, playableMessageNextTo: message) else {
            return
        }
        guard next.category.hasSuffix("_AUDIO"), next.mediaStatus == MediaStatus.CANCELED.rawValue || next.mediaStatus == MediaStatus.PENDING.rawValue else {
            return
        }
        let message = Message.createMessage(message: message)
        let job = TranscriptAttachmentDownloadJob(transcriptMessageId: transcriptMessageId, message: message)
        ConcurrentJobQueue.shared.addJob(job: job)
    }
    
}
