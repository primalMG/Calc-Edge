//
//  JournalInsightsView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 03/02/2026.
//

import SwiftUI
import SwiftData

struct JournalInsightsView: View {
    @Query(sort: \Trade.openedAt, order: .reverse) private var trades: [Trade]

    @State private var selectedTimeRange: InsightTimeRange = .all
    @State private var selectedEdgeCategory = "All"

    private let statColumns = [
        GridItem(.adaptive(minimum: 180), spacing: 12)
    ]

    var body: some View {
        let filteredTrades = selectedTimeRange.filter(trades)
        let calculator = TradeInsightsCalculator(trades: filteredTrades)
        let insights = calculator.calculate()

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                JournalInsightsHeader()
                InsightTimeRangePicker(selection: $selectedTimeRange)

                if filteredTrades.isEmpty {
                    JournalInsightsEmptyState()
                } else {
                    insightsContent(insights: insights, minSampleSize: calculator.minSampleSize)
                }
            }
            .padding()
        }
        .navigationTitle("Journal Insights")
    }

    @ViewBuilder
    private func insightsContent(insights: TradeInsights, minSampleSize: Int) -> some View {
        insightReadinessBanner(for: insights)

        if !insights.highlights.isEmpty {
            LazyVGrid(columns: statColumns, alignment: .leading, spacing: 12) {
                ForEach(insights.highlights) { highlight in
                    InsightHighlightCard(highlight: highlight)
                }
            }
        }

        if let nextReviewFocus = insights.nextReviewFocus {
            ReviewFocusCard(focus: nextReviewFocus)
        }

        JournalInsightsOverviewSection(insights: insights, columns: statColumns)
        JournalInsightsEdgeMapSection(
            insights: insights,
            minSampleSize: minSampleSize,
            selectedCategory: $selectedEdgeCategory
        )
        JournalInsightsStrengthsDragSection(insights: insights, minSampleSize: minSampleSize)
        JournalInsightsRiskEfficiencySection(insights: insights, columns: statColumns)
        JournalInsightsProcessQualitySection(insights: insights, columns: statColumns)
        JournalInsightsDataQualitySection(insights: insights, columns: statColumns)
        JournalInsightsCountedItemsSection(
            title: "Common Mistakes",
            emptyText: "No mistake tags recorded yet.",
            items: insights.topMistakes
        )
        JournalInsightsCountedItemsSection(
            title: "Exit Reasons",
            emptyText: "No exit reasons recorded yet.",
            items: insights.exitReasons
        )
    }

    @ViewBuilder
    private func insightReadinessBanner(for insights: TradeInsights) -> some View {
        if insights.closedTrades == 0 {
            InsightsBanner(text: "Add closed trades to unlock performance insights.")
        } else if insights.pricedTrades == 0 {
            InsightsBanner(text: "Add entry and exit prices to closed trades to calculate win rates and R multiples.")
        } else if insights.riskDefinedTrades == 0 {
            InsightsBanner(text: "Add stop prices to closed trades to calculate expectancy, profit factor, and average winner/loser.")
        }
    }
}

private struct JournalInsightsHeader: View {
    var body: some View {
        Text("Trade-based performance breakdowns and process signals.")
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct InsightTimeRangePicker: View {
    @Binding var selection: InsightTimeRange

    var body: some View {
        Picker("Time Range", selection: $selection) {
            ForEach(InsightTimeRange.allCases) { range in
                Text(range.title).tag(range)
            }
        }
        .pickerStyle(.segmented)
    }
}

private struct JournalInsightsEmptyState: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No journal entries yet.")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Log a trade in the journal to unlock insights about your edge, process, and risk habits.")
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    JournalInsightsView()
}
