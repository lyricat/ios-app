import UIKit
import MixinServices

class StickerStorePreviewCell: UICollectionViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    var onStickerOperation: (() -> Void)?
    var stickerStoreItem: StickerStoreItem! {
        didSet {
            nameLabel.text = stickerStoreItem.album.name
            if stickerStoreItem.isAdded {
                addButton.setTitle(R.string.localizable.sticker_store_added(), for: .normal)
                addButton.backgroundColor = R.color.sticker_button_background_disabled()
                addButton.setTitleColor(R.color.sticker_button_text_disabled(), for: .normal)
            } else {
                addButton.setTitle(R.string.localizable.sticker_store_add(), for: .normal)
                addButton.backgroundColor = R.color.theme()
                addButton.setTitleColor(.white, for: .normal)
            }
            collectionView.reloadData()
        }
    }
    private let cellCountPerRow = 4
    
    @IBAction func stickerAction(_ sender: Any) {
        onStickerOperation?()
    }
    
}

extension StickerStorePreviewCell: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return min(cellCountPerRow, stickerStoreItem.stickers.count)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: R.reuseIdentifier.sticker_preview, for: indexPath)!
        if indexPath.item < stickerStoreItem.stickers.count {
            cell.stickerView.load(sticker: stickerStoreItem.stickers[indexPath.item])
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? StickerPreviewCell else {
            return
        }
        cell.stickerView.startAnimating()
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? StickerPreviewCell else {
            return
        }
        cell.stickerView.stopAnimating()
    }
    
}
