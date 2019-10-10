import Foundation

class SharedMediaCategorizer<ItemType: SharedMediaItem> {
    
    var categorizedItems = [ItemType]()
    var dates = [String]()
    var itemGroups = [String: [ItemType]]()
    var wantsMoreInput = true
    
    required init() {
        
    }
    
    func input(items: [ItemType], didLoadEarliest: Bool) {
        self.categorizedItems = items
        for item in items {
            let date = item.createdAt.toUTCDate()
            let title = DateFormatter.dateSimple.string(from: date)
            if itemGroups[title] != nil {
                itemGroups[title]!.append(item)
            } else {
                dates.append(title)
                itemGroups[title] = [item]
            }
        }
        wantsMoreInput = false
    }
    
}
