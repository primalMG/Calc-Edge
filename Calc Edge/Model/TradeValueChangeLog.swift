import Foundation
import SwiftData

@Model
final class TradeValueChangeLog {
    var id: UUID = UUID()
    var changedAt: Date = Date.now
    var summary: String = ""
    var detail: String?

    var previousShareCount: Decimal = 0
    var newShareCount: Decimal = 0
    var previousAveragePrice: Decimal?
    var newAveragePrice: Decimal?

    var trade: Trade?

    init(
        changedAt: Date = .now,
        summary: String,
        detail: String? = nil,
        previousShareCount: Decimal,
        newShareCount: Decimal,
        previousAveragePrice: Decimal?,
        newAveragePrice: Decimal?
    ) {
        self.changedAt = changedAt
        self.summary = summary
        self.detail = detail
        self.previousShareCount = previousShareCount
        self.newShareCount = newShareCount
        self.previousAveragePrice = previousAveragePrice
        self.newAveragePrice = newAveragePrice
    }
}

extension Trade {
    func appendValueChangeLog(
        summary: String,
        detail: String?,
        previous: TradePositionSummary,
        current: TradePositionSummary
    ) {
        if valueChangeLogs == nil {
            valueChangeLogs = []
        }

        valueChangeLogs?.append(
            TradeValueChangeLog(
                summary: summary,
                detail: detail,
                previousShareCount: previous.currentShareCount,
                newShareCount: current.currentShareCount,
                previousAveragePrice: previous.averagePrice,
                newAveragePrice: current.averagePrice
            )
        )
    }
}
