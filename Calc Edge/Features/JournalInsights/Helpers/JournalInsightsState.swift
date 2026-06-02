import Foundation

struct JournalInsightsState {
    var filteredTrades: [Trade] = []
    var insights: TradeInsights?
}

struct JournalInsightsRefreshToken: Equatable {
    let timeRange: InsightTimeRange
    let trades: [TradeToken]

    @MainActor
    init(timeRange: InsightTimeRange, trades: [Trade]) {
        self.timeRange = timeRange
        self.trades = trades.map(TradeToken.init)
    }

    struct TradeToken: Equatable {
        let tradeId: UUID
        let openedAt: Date
        let closedAt: Date?
        let account: String?
        let instrument: InstrumentType
        let direction: TradeDirection
        let strategyName: String?
        let setupType: String?
        let timeframe: String?
        let confidenceScore: Int
        let isAPlusSetup: Bool
        let entryPrice: String?
        let exitPrice: String?
        let stopPrice: String?
        let targetPrice: String?
        let commissions: String?
        let slippage: String?
        let mae: String?
        let mfe: String?
        let exitReason: ExitReason?
        let review: ReviewToken?
        let context: ContextToken?

        @MainActor
        init(trade: Trade) {
            tradeId = trade.tradeId
            openedAt = trade.openedAt
            closedAt = trade.closedAt
            account = trade.account
            instrument = trade.instrument
            direction = trade.direction
            strategyName = trade.strategyName
            setupType = trade.setupType
            timeframe = trade.timeframe
            confidenceScore = trade.confidenceScore
            isAPlusSetup = trade.isAPlusSetup
            entryPrice = Self.decimal(trade.entryPrice)
            exitPrice = Self.decimal(trade.exitPrice)
            stopPrice = Self.decimal(trade.stopPrice)
            targetPrice = Self.decimal(trade.targetPrice)
            commissions = Self.decimal(trade.commissions)
            slippage = Self.decimal(trade.slippage)
            mae = Self.decimal(trade.mae)
            mfe = Self.decimal(trade.mfe)
            exitReason = trade.exitReason
            review = trade.review.map(ReviewToken.init)
            context = trade.context.map(ContextToken.init)
        }

        private static func decimal(_ value: Decimal?) -> String? {
            value.map { NSDecimalNumber(decimal: $0).stringValue }
        }
    }

    struct ReviewToken: Equatable {
        let followedPlan: Bool
        let entryQuality: Int
        let exitQuality: Int
        let emotionalState: EmotionalState
        let mistakeType: String?
        let wouldRetake: Bool

        @MainActor
        init(review: TradeReview) {
            followedPlan = review.followedPlan
            entryQuality = review.entryQuality
            exitQuality = review.exitQuality
            emotionalState = review.emotionalState
            mistakeType = review.mistakeType
            wouldRetake = review.wouldRetake
        }
    }

    struct ContextToken: Equatable {
        let marketRegime: MarketRegime
        let timeOfDayTag: String?

        @MainActor
        init(context: TradeContext) {
            marketRegime = context.marketRegime
            timeOfDayTag = context.timeOfDayTag
        }
    }
}
