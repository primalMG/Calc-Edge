//
//  JournalInsightsView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 03/02/2026.
//

import SwiftUI
import SwiftData

struct JournalInsightsView: View {
    @Query private var trades: [Trade]

    private let usesMockInsights = false

    @State private var selectedTimeRange: InsightTimeRange = .all
    @State private var selectedEdgeCategory = "All"
    @State private var insightState = JournalInsightsState()

    private let statColumns = [
        GridItem(.adaptive(minimum: 180), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                JournalInsightsHeader()
                InsightTimeRangePicker(selection: $selectedTimeRange)

                if insightState.filteredTrades.isEmpty && !usesMockInsights {
                    JournalInsightsEmptyState()
                } else if let insights = insightState.insights {
                    insightsContent(insights: insights, trades: filteredTrades, minSampleSize: 30)
                }
            }
            .padding()
        }
        .navigationTitle("Journal Insights")
        .task(id: insightRefreshToken) {
            refreshInsights()
        }
    }

    private var filteredTrades: [Trade] {
        insightState.filteredTrades
    }

    private var insightRefreshToken: JournalInsightsRefreshToken {
        JournalInsightsRefreshToken(timeRange: selectedTimeRange, trades: trades)
    }

    private func refreshInsights() {
        let filteredTrades = selectedTimeRange.filter(trades)
        let insights = usesMockInsights ? TradeInsights.mock : TradeInsightsCalculator(trades: filteredTrades).calculate()
        insightState = JournalInsightsState(filteredTrades: filteredTrades, insights: insights)
    }

    @ViewBuilder
    private func insightsContent(insights: TradeInsights, trades: [Trade], minSampleSize: Int) -> some View {
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
            trades: trades,
            minSampleSize: minSampleSize,
            selectedCategory: $selectedEdgeCategory
        )
        JournalInsightsStrengthsDragSection(insights: insights, trades: trades, minSampleSize: minSampleSize)
        JournalInsightsRiskEfficiencySection(insights: insights, columns: statColumns)
        JournalInsightsProcessQualitySection(insights: insights, columns: statColumns)
        JournalInsightsDataQualitySection(insights: insights, columns: statColumns)
        JournalInsightsCountedItemsSection(
            title: "Common Mistakes",
            emptyText: "No mistake tags recorded yet.",
            items: insights.topMistakes,
            trades: trades,
            kind: .mistake
        )
        JournalInsightsCountedItemsSection(
            title: "Exit Reasons",
            emptyText: "No exit reasons recorded yet.",
            items: insights.exitReasons,
            trades: trades,
            kind: .exitReason
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


//MARK: Testing full functionality of the view
private extension TradeInsights {
    static let mock: TradeInsights = {
        let breakout = TradeInsightSegmentPerformance(
            id: "Setup:Breakout",
            category: "Setup",
            label: "Breakout",
            trades: 18,
            wins: 12,
            winRate: 0.67,
            expectancy: 1.24,
            averageWinner: 2.1,
            averageLoser: -0.82,
            profitFactor: 2.35
        )
        let pullback = TradeInsightSegmentPerformance(
            id: "Setup:Pullback",
            category: "Setup",
            label: "Pullback",
            trades: 14,
            wins: 8,
            winRate: 0.57,
            expectancy: 0.42,
            averageWinner: 1.38,
            averageLoser: -0.86,
            profitFactor: 1.52
        )
        let earlyReversal = TradeInsightSegmentPerformance(
            id: "Setup:Early Reversal",
            category: "Setup",
            label: "Early Reversal",
            trades: 9,
            wins: 3,
            winRate: 0.33,
            expectancy: -0.36,
            averageWinner: 1.1,
            averageLoser: -1.04,
            profitFactor: 0.72
        )
        let longDirection = TradeInsightSegmentPerformance(
            id: "Direction:Long",
            category: "Direction",
            label: "Long",
            trades: 26,
            wins: 17,
            winRate: 0.65,
            expectancy: 0.74,
            averageWinner: 1.72,
            averageLoser: -0.93,
            profitFactor: 1.98
        )
        let shortDirection = TradeInsightSegmentPerformance(
            id: "Direction:Short",
            category: "Direction",
            label: "Short",
            trades: 15,
            wins: 6,
            winRate: 0.4,
            expectancy: -0.18,
            averageWinner: 1.2,
            averageLoser: -1.1,
            profitFactor: 0.81
        )
        let equities = TradeInsightSegmentPerformance(
            id: "Instrument:Stock",
            category: "Instrument",
            label: "Stock",
            trades: 31,
            wins: 19,
            winRate: 0.61,
            expectancy: 0.58,
            averageWinner: 1.64,
            averageLoser: -0.91,
            profitFactor: 1.72
        )
        let options = TradeInsightSegmentPerformance(
            id: "Instrument:Option",
            category: "Instrument",
            label: "Option",
            trades: 10,
            wins: 4,
            winRate: 0.4,
            expectancy: -0.12,
            averageWinner: 1.45,
            averageLoser: -1.05,
            profitFactor: 0.92
        )
        let aPlus = TradeInsightSegmentPerformance(
            id: "Confidence:Score 5",
            category: "Confidence",
            label: "Score 5",
            trades: 11,
            wins: 8,
            winRate: 0.73,
            expectancy: 1.08,
            averageWinner: 1.9,
            averageLoser: -0.78,
            profitFactor: 2.8
        )

        return TradeInsights(
            totalTrades: 48,
            closedTrades: 41,
            pricedTrades: 41,
            riskDefinedTrades: 36,
            winRate: 0.59,
            averageWinner: 1.72,
            averageLoser: -0.94,
            expectancy: 0.54,
            profitFactor: 1.84,
            averageHoldTime: 60 * 60 * 31,
            aPlusWinRate: 0.73,
            nonAPlusWinRate: 0.51,
            aPlusExpectancy: 1.08,
            nonAPlusExpectancy: 0.23,
            followedPlanExpectancy: 0.78,
            brokePlanExpectancy: -0.41,
            followedPlanRate: 0.82,
            wouldRetakeRate: 0.71,
            entryQualityAverage: 4.1,
            exitQualityAverage: 3.6,
            targetHitRate: 0.34,
            averagePlannedR: 2.18,
            averageMAE: 0.63,
            averageMFE: 1.46,
            averageCostDrag: 8.42,
            highConfidenceLosers: 3,
            lowConfidenceWinners: 2,
            highlights: [
                TradeInsightHighlight(
                    id: "expectancy",
                    title: "Current Edge",
                    value: "0.54R",
                    detail: "Average result per risk-defined trade.",
                    tone: .positive
                ),
                TradeInsightHighlight(
                    id: "best-setup",
                    title: "Best Setup",
                    value: "Breakout",
                    detail: "18 trades, 1.24R expectancy.",
                    tone: .positive
                ),
                TradeInsightHighlight(
                    id: "drag",
                    title: "Drag",
                    value: "Early Reversal",
                    detail: "9 trades, -0.36R expectancy.",
                    tone: .caution
                ),
                TradeInsightHighlight(
                    id: "plan-delta",
                    title: "Plan Delta",
                    value: "1.19R",
                    detail: "Followed-plan trades versus broken-plan trades.",
                    tone: .positive
                )
            ],
            nextReviewFocus: TradeInsightReviewFocus(
                title: "Reduce Early Reversal exposure",
                detail: "This setup is negative expectancy in the current sample. Pause it or add a stricter entry filter before taking the next one."
            ),
            bestSetup: breakout,
            worstSetup: earlyReversal,
            edgeMapSegments: [
                breakout,
                aPlus,
                longDirection,
                equities,
                pullback,
                options,
                shortDirection,
                earlyReversal
            ],
            performanceByInstrument: [equities, options],
            performanceByDirection: [longDirection, shortDirection],
            performanceByAccount: [
                TradeInsightSegmentPerformance(
                    id: "Account:Main",
                    category: "Account",
                    label: "Main",
                    trades: 28,
                    wins: 18,
                    winRate: 0.64,
                    expectancy: 0.71,
                    averageWinner: 1.8,
                    averageLoser: -0.86,
                    profitFactor: 2.05
                )
            ],
            strengths: [breakout, aPlus, longDirection],
            weaknesses: [earlyReversal, shortDirection, options],
            topMistakes: [
                TradeInsightCountedItem(id: "Mistake:FOMO Entry", label: "FOMO Entry", count: 7, percentage: 0.29),
                TradeInsightCountedItem(id: "Mistake:Moved Stop", label: "Moved Stop", count: 4, percentage: 0.17),
                TradeInsightCountedItem(id: "Mistake:Late Exit", label: "Late Exit", count: 3, percentage: 0.13)
            ],
            exitReasons: [
                TradeInsightCountedItem(id: "ExitReason:targetHit", label: "Target Hit", count: 14, percentage: 0.34),
                TradeInsightCountedItem(id: "ExitReason:manual", label: "Manual", count: 12, percentage: 0.29),
                TradeInsightCountedItem(id: "ExitReason:stopHit", label: "Stop Hit", count: 9, percentage: 0.22)
            ],
            reviewCoverage: 0.83,
            stopCoverage: 0.88,
            exitReasonCoverage: 0.91
        )
    }()
}
