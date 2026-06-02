import Foundation

struct ReviewCalendarState {
    var days: [ReviewCalendarDaySummary] = []
}

struct ReviewCalendarRefreshToken: Equatable {
    let visibleMonthStart: Date
    let mode: ReviewCalendarDateMode
    let trades: [TradeToken]

    @MainActor
    init(
        visibleMonth: Date,
        calendar: Calendar,
        mode: ReviewCalendarDateMode,
        trades: [Trade]
    ) {
        visibleMonthStart = calendar.dateInterval(of: .month, for: visibleMonth)?.start ?? visibleMonth
        self.mode = mode
        self.trades = trades.map(TradeToken.init)
    }

    struct TradeToken: Equatable {
        let tradeId: UUID
        let openedAt: Date
        let closedAt: Date?
        let direction: TradeDirection
        let entryPrice: String?
        let exitPrice: String?
        let stopPrice: String?
        let commissions: String?
        let slippage: String?
        let exitReason: ExitReason?
        let review: ReviewToken?

        @MainActor
        init(trade: Trade) {
            tradeId = trade.tradeId
            openedAt = trade.openedAt
            closedAt = trade.closedAt
            direction = trade.direction
            entryPrice = Self.decimal(trade.entryPrice)
            exitPrice = Self.decimal(trade.exitPrice)
            stopPrice = Self.decimal(trade.stopPrice)
            commissions = Self.decimal(trade.commissions)
            slippage = Self.decimal(trade.slippage)
            exitReason = trade.exitReason
            review = trade.review.map(ReviewToken.init)
        }

        private static func decimal(_ value: Decimal?) -> String? {
            value.map { NSDecimalNumber(decimal: $0).stringValue }
        }
    }

    struct ReviewToken: Equatable {
        let followedPlan: Bool
        let mistakeType: String?

        @MainActor
        init(review: TradeReview) {
            followedPlan = review.followedPlan
            mistakeType = review.mistakeType
        }
    }
}
