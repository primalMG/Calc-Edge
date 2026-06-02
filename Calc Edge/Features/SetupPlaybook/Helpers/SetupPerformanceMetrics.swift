import Foundation

struct SetupPerformanceMetrics: Equatable {
    static let empty = SetupPerformanceMetrics(
        tradeCount: 0,
        winRate: "No data",
        expectancy: "No data",
        aPlusRate: "No data"
    )

    let tradeCount: Int
    let winRate: String
    let expectancy: String
    let aPlusRate: String

    @MainActor
    init(trades: [Trade]) {
        let insights = TradeInsightsCalculator(trades: trades).calculate()

        tradeCount = trades.count
        winRate = JournalInsightsFormatting.percentage(insights.winRate)
        expectancy = JournalInsightsFormatting.rMultiple(insights.expectancy)
        aPlusRate = JournalInsightsFormatting.percentage(Self.aPlusRate(for: trades))
    }

    private init(
        tradeCount: Int,
        winRate: String,
        expectancy: String,
        aPlusRate: String
    ) {
        self.tradeCount = tradeCount
        self.winRate = winRate
        self.expectancy = expectancy
        self.aPlusRate = aPlusRate
    }

    private static func aPlusRate(for trades: [Trade]) -> Double? {
        guard !trades.isEmpty else { return nil }
        let aPlusCount = trades.filter(\.isAPlusSetup).count
        return Double(aPlusCount) / Double(trades.count)
    }
}

struct SetupPerformanceToken: Hashable {
    let trades: [TradeToken]

    init(trades: [Trade]) {
        self.trades = trades.map(TradeToken.init).sorted { lhs, rhs in
            lhs.tradeId.uuidString < rhs.tradeId.uuidString
        }
    }

    struct TradeToken: Hashable {
        let tradeId: UUID
        let isAPlusSetup: Bool
        let entryPrice: String?
        let exitPrice: String?
        let stopPrice: String?
        let targetPrice: String?

        @MainActor
        init(trade: Trade) {
            tradeId = trade.tradeId
            isAPlusSetup = trade.isAPlusSetup
            entryPrice = Self.decimal(trade.entryPrice)
            exitPrice = Self.decimal(trade.exitPrice)
            stopPrice = Self.decimal(trade.stopPrice)
            targetPrice = Self.decimal(trade.targetPrice)
        }

        private static func decimal(_ value: Decimal?) -> String? {
            guard let value else { return nil }
            return NSDecimalNumber(decimal: value).stringValue
        }
    }
}
