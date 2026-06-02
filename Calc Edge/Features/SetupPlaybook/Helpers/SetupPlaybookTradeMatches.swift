import SwiftData
import SwiftUI

struct SetupPlaybookTradeMatches: View {
    @Bindable var setup: TradingSetup
    @Query(sort: \Trade.openedAt, order: .reverse) private var matchingTrades: [Trade]

    init(setup: TradingSetup) {
        self.setup = setup

        let name = Self.normalized(setup.name)
        let strategyName = Self.normalized(setup.strategyName)
        let timeframe = Self.normalized(setup.timeframe)
        let catalyst = Self.normalized(setup.catalyst)
        let hasName = !name.isEmpty
        let hasStrategyName = !strategyName.isEmpty
        let hasTimeframe = !timeframe.isEmpty
        let hasCatalyst = !catalyst.isEmpty

        _matchingTrades = Query(
            filter: #Predicate<Trade> { trade in
                (hasName && trade.setupType == name)
                    || (hasStrategyName && trade.strategyName == strategyName)
                    || (hasTimeframe && trade.timeframe == timeframe)
                    || (hasCatalyst && trade.catalyst == catalyst)
            },
            sort: \Trade.openedAt,
            order: .reverse
        )
    }

    var body: some View {
        SetupPlaybookTradeMatchesContent(
            setup: setup,
            matchingTrades: matchingTrades
        )
        .id(queryToken)
    }

    private var queryToken: SetupPlaybookTradeMatchToken {
        SetupPlaybookTradeMatchToken(setup: setup)
    }

    private static func normalized(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

private struct SetupPlaybookTradeMatchesContent: View {
    let setup: TradingSetup
    let matchingTrades: [Trade]

    var body: some View {
        PlaybookFormSection("Journal Stats") {
            SetupPerformanceSummary(setup: setup, trades: matchingTrades)
        }

        if !matchingTrades.isEmpty {
            PlaybookFormSection("Matching Trades") {
                ForEach(matchingTrades.prefix(8)) { trade in
                    NavigationLink {
                        TradeJournalDetailView(trade: trade)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(trade.ticker)
                                .font(.headline)
                            Text(trade.openedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}

private struct SetupPerformanceSummary: View {
    let setup: TradingSetup
    let trades: [Trade]

    @State private var metrics = SetupPerformanceMetrics.empty

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            InfoStatCard(title: "Trades", value: "\(metrics.tradeCount)")
            InfoStatCard(title: "Win Rate", value: metrics.winRate)
            InfoStatCard(title: "Expectancy", value: metrics.expectancy)
            InfoStatCard(title: "A+ Rate", value: metrics.aPlusRate)
        }
        .task(id: SetupPerformanceToken(trades: trades)) {
            metrics = SetupPerformanceMetrics(trades: trades)
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 140), spacing: 12)]
    }
}

private struct SetupPlaybookTradeMatchToken: Hashable {
    let name: String
    let strategyName: String
    let timeframe: String
    let catalyst: String

    init(setup: TradingSetup) {
        name = Self.normalized(setup.name)
        strategyName = Self.normalized(setup.strategyName)
        timeframe = Self.normalized(setup.timeframe)
        catalyst = Self.normalized(setup.catalyst)
    }

    private static func normalized(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
