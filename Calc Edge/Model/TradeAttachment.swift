import Foundation
import SwiftData

@Model
final class TradeAttachment {
    var kind: String
    var createdAt: Date
    var note: String?

    @Attribute(.externalStorage) var imageData: Data?
    var urlString: String?

    init(
        kind: String,
        createdAt: Date = .now,
        note: String? = nil,
        imageData: Data? = nil,
        urlString: String? = nil
    ) {
        self.kind = kind
        self.createdAt = createdAt
        self.note = note
        self.imageData = imageData
        self.urlString = urlString
    }
}
