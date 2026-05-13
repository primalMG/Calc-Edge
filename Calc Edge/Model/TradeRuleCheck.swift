import Foundation
import SwiftData

@Model
final class TradeRuleCheck {
    var checkId: UUID = UUID()
    var followed: Bool = true
    var note: String?
    var createdAt: Date = Date.now

    var rule: TradingRule?
    var review: TradeReview?

    init(
        checkId: UUID = UUID(),
        followed: Bool = true,
        note: String? = nil,
        createdAt: Date = .now,
        rule: TradingRule? = nil,
        review: TradeReview? = nil
    ) {
        self.checkId = checkId
        self.followed = followed
        self.note = note
        self.createdAt = createdAt
        self.rule = rule
        self.review = review
    }
}

