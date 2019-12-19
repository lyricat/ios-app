import Foundation
import WCDBSwift

public struct Album: BaseCodable {
    
    static var tableName: String = "albums"
    
    let albumId: String
    let name: String
    let iconUrl: String
    let createdAt: String
    let updatedAt: String
    let userId: String
    let category: String
    let description: String
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = Album
        case albumId = "album_id"
        case name
        case iconUrl = "icon_url"
        case createdAt = "created_at"
        case updatedAt = "update_at"
        case userId = "user_id"
        case category
        case description
        
        public static let objectRelationalMapping = TableBinding(CodingKeys.self)
        public static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            return [
                albumId: ColumnConstraintBinding(isPrimary: true)
            ]
        }
    }
    
}

enum AlbumCategory: String {
    case PERSONAL
    case SYSTEM
}
