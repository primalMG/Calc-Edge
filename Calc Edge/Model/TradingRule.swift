import Foundation
import SwiftData

@Model
final class TradingRule {
    var ruleId: UUID = UUID()
    var title: String = ""
    var category: String = ""
    @Attribute(.externalStorage) var ruleDescription: String?
    @Attribute(.externalStorage) var checklistPrompt: String?
    var isActive: Bool = true
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    @Relationship(deleteRule: .cascade, inverse: \TradeRuleCheck.rule) var checks: [TradeRuleCheck]? = []

    init(
        ruleId: UUID = UUID(),
        title: String,
        category: String = "",
        ruleDescription: String? = nil,
        checklistPrompt: String? = nil,
        isActive: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.ruleId = ruleId
        self.title = title
        self.category = category
        self.ruleDescription = ruleDescription
        self.checklistPrompt = checklistPrompt
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

