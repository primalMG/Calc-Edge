import SwiftUI

struct TradeInsightDrillDownView: View {
    let title: String
    let subtitle: String
    let trades: [Trade]

    private var calculator: TradeInsightsCalculator {
        TradeInsightsCalculator(trades: trades)
    }

    private var insights: TradeInsights {
        calculator.calculate()
    }

    private var sortedTrades: [Trade] {
        trades.sorted { $0.openedAt > $1.openedAt }
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(subtitle)
                        .foregroundStyle(.secondary)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 10)], spacing: 10) {
                        InfoStatCard(title: "Trades", value: "\(trades.count)")
                        InfoStatCard(title: "Win Rate", value: JournalInsightsFormatting.percent(insights.winRate))
                        InfoStatCard(
                            title: "Expectancy",
                            value: JournalInsightsFormatting.rMultiple(insights.expectancy),
                            accentColor: JournalInsightsFormatting.valueColor(for: insights.expectancy)
                        )
                        InfoStatCard(
                            title: "Profit Factor",
                            value: JournalInsightsFormatting.profitFactor(insights.profitFactor),
                            accentColor: JournalInsightsFormatting.profitFactorColor(for: insights.profitFactor)
                        )
                    }
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }

            Section("Trades") {
                if sortedTrades.isEmpty {
                    ContentUnavailableView(
                        "No Matching Trades",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("No trades are currently linked to this insight.")
                    )
                } else {
                    ForEach(sortedTrades) { trade in
                        NavigationLink {
                            TradeJournalDetailView(trade: trade)
                        } label: {
                            TradeJournalRow(trade: trade)
                        }
                    }
                }
            }
        }
        .navigationTitle(title)
    }
}
