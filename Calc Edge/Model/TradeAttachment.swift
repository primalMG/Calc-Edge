import Foundation
import SwiftData

@Model
final class TradeAttachment {
    var kind: String = ""
    var createdAt: Date = Date.now
    var note: String?

    @Attribute(.externalStorage) var imageData: Data?
    var urlString: String?
    var trade: Trade?

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
