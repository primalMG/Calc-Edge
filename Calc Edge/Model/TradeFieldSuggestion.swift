import Foundation
import SwiftData

@Model
final class TradeFieldSuggestion {
    var uniqueKey: String = ""
    var field: String = ""
    var value: String = ""
    var useCount: Int = 1
    var lastUsedAt: Date = Date.now

    init(field: String, value: String, useCount: Int = 1, lastUsedAt: Date = .now) {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        self.uniqueKey = Self.makeUniqueKey(field: field, value: trimmedValue)
        self.field = field
        self.value = trimmedValue
        self.useCount = useCount
        self.lastUsedAt = lastUsedAt
    }

    static func makeUniqueKey(field: String, value: String) -> String {
        "\(field.lowercased())|\(value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())"
    }
}
