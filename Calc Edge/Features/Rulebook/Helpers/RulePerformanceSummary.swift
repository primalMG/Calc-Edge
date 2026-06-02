import SwiftUI

struct RulePerformanceSummary: View {
    let rule: TradingRule

    @State private var metrics = RulePerformanceMetrics.empty

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            InfoStatCard(title: "Checked", value: "\(metrics.checkedCount)")
            InfoStatCard(title: "Followed", value: metrics.followedPercentage)
            InfoStatCard(title: "Broken", value: "\(metrics.brokenCount)", accentColor: metrics.brokenCount == 0 ? .green : .orange)
            InfoStatCard(title: "Avg R When Followed", value: metrics.averageRWhenFollowed)
        }
        .task(id: RulePerformanceToken(rule: rule)) {
            metrics = RulePerformanceMetrics(rule: rule)
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 140), spacing: 12)]
    }
}

struct RulePerformanceMetrics: Equatable {
    static let empty = RulePerformanceMetrics(
        checkedCount: 0,
        followedPercentage: "No data",
        brokenCount: 0,
        averageRWhenFollowed: "No data"
    )

    let checkedCount: Int
    let followedPercentage: String
    let brokenCount: Int
    let averageRWhenFollowed: String

    @MainActor
    init(rule: TradingRule) {
        let checks = rule.checks ?? []
        let followed = checks.filter(\.followed)
        let broken = checks.count - followed.count

        checkedCount = checks.count
        followedPercentage = Self.percentage(followed.count, checks.count)
        brokenCount = broken
        averageRWhenFollowed = Self.averageR(for: followed)
    }

    private init(
        checkedCount: Int,
        followedPercentage: String,
        brokenCount: Int,
        averageRWhenFollowed: String
    ) {
        self.checkedCount = checkedCount
        self.followedPercentage = followedPercentage
        self.brokenCount = brokenCount
        self.averageRWhenFollowed = averageRWhenFollowed
    }

    private static func percentage(_ count: Int, _ total: Int) -> String {
        guard total > 0 else { return "No data" }
        return "\(Int((Double(count) / Double(total) * 100).rounded()))%"
    }

    private static func averageR(for checks: [TradeRuleCheck]) -> String {
        let trades = checks.compactMap { $0.review?.trade }
        let calculator = TradeInsightsCalculator(trades: trades)
        let values = trades.compactMap(calculator.rMultiple)

        guard !values.isEmpty else { return "No data" }
        let average = values.reduce(0, +) / Double(values.count)
        return "\(average.formatted(.number.precision(.fractionLength(2))))R"
    }
}

struct RulePerformanceToken: Hashable {
    let checks: [CheckToken]

    init(rule: TradingRule) {
        checks = (rule.checks ?? []).map(CheckToken.init).sorted { lhs, rhs in
            lhs.checkId.uuidString < rhs.checkId.uuidString
        }
    }

    struct CheckToken: Hashable {
        let checkId: UUID
        let followed: Bool
        let tradeId: UUID?
        let entryPrice: String?
        let exitPrice: String?
        let stopPrice: String?
        let targetPrice: String?

        @MainActor
        init(check: TradeRuleCheck) {
            let trade = check.review?.trade

            checkId = check.checkId
            followed = check.followed
            tradeId = trade?.tradeId
            entryPrice = Self.decimal(trade?.entryPrice)
            exitPrice = Self.decimal(trade?.exitPrice)
            stopPrice = Self.decimal(trade?.stopPrice)
            targetPrice = Self.decimal(trade?.targetPrice)
        }

        private static func decimal(_ value: Decimal?) -> String? {
            guard let value else { return nil }
            return NSDecimalNumber(decimal: value).stringValue
        }
    }
}
