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

    private let statColumns = [
        GridItem(.adaptive(minimum: 180), spacing: 12)
    ]

    var body: some View {
        let calculator = TradeInsightsCalculator(trades: trades)
        let insights = calculator.calculate()

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if trades.isEmpty {
                    emptyState
                } else {
                    if insights.closedTrades == 0 {
                        InsightsBanner(text: "Add closed trades to unlock performance insights.")
                    } else if insights.pricedTrades == 0 {
                        InsightsBanner(text: "Add entry and exit prices to closed trades to calculate win rates and R multiples.")
                    }

                    InfoSection(title: "Overview") {
                        LazyVGrid(columns: statColumns, alignment: .leading, spacing: 12) {
                            InfoStatCard(title: "Total Trades", value: "\(insights.totalTrades)")
                            InfoStatCard(title: "Closed Trades", value: "\(insights.closedTrades)")
                            InfoStatCard(title: "Win Rate", value: formatPercent(insights.winRate))
                            InfoStatCard(title: "Avg R", value: formatR(insights.averageR))
                            InfoStatCard(title: "Avg Hold", value: formatDuration(insights.averageHoldTime))
                            InfoStatCard(title: "A+ Win Rate", value: formatPercent(insights.aPlusWinRate))
                        }
                    }

                    InfoSection(title: "Where You Excel") {
                        if insights.strengths.isEmpty {
                            Text("Not enough categorized trades yet. Add at least \(calculator.minSampleSize) trades per category (strategy/setup/timeframe).")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(insights.strengths) { segment in
                                InfoRow(
                                    title: "\(segment.category): \(segment.label)",
                                    detail: formatSegmentDetail(segment)
                                )
                            }
                        }
                    }

                    InfoSection(title: "Needs Attention") {
                        if insights.weaknesses.isEmpty {
                            Text("No underperforming segments yet based on available data.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(insights.weaknesses) { segment in
                                InfoRow(
                                    title: "\(segment.category): \(segment.label)",
                                    detail: formatSegmentDetail(segment)
                                )
                            }
                        }
                    }

                    InfoSection(title: "Process Quality") {
                        LazyVGrid(columns: statColumns, alignment: .leading, spacing: 12) {
                            InfoStatCard(title: "Followed Plan", value: formatPercent(insights.followedPlanRate))
                            InfoStatCard(title: "Would Retake", value: formatPercent(insights.wouldRetakeRate))
                            InfoStatCard(title: "Entry Quality", value: formatRating(insights.entryQualityAverage))
                            InfoStatCard(title: "Exit Quality", value: formatRating(insights.exitQualityAverage))
                        }
                    }

                    InfoSection(title: "Data Quality") {
                        LazyVGrid(columns: statColumns, alignment: .leading, spacing: 12) {
                            InfoStatCard(title: "Review Coverage", value: formatPercent(insights.reviewCoverage))
                            InfoStatCard(title: "Stop Coverage", value: formatPercent(insights.stopCoverage))
                            InfoStatCard(title: "Exit Reason Coverage", value: formatPercent(insights.exitReasonCoverage))
                        }
                    }

                    InfoSection(title: "Common Mistakes") {
                        if insights.topMistakes.isEmpty {
                            Text("No mistake tags recorded yet.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(insights.topMistakes) { item in
                                InfoRow(
                                    title: item.label,
                                    detail: "\(item.count) trades • \(formatPercent(item.percentage))"
                                )
                            }
                        }
                    }

                    InfoSection(title: "Exit Reasons") {
                        if insights.exitReasons.isEmpty {
                            Text("No exit reasons recorded yet.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(insights.exitReasons) { item in
                                InfoRow(
                                    title: item.label,
                                    detail: "\(item.count) trades • \(formatPercent(item.percentage))"
                                )
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Journal Insights")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Journal Insights")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("Trade-based performance breakdowns and process signals.")
                .foregroundStyle(.secondary)
        }
    }

    private var emptyState: some View {
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

    private func formatPercent(_ value: Double?) -> String {
        guard let value else { return "N/A" }
        return value.formatted(.percent.precision(.fractionLength(0)))
    }

    private func formatR(_ value: Double?) -> String {
        guard let value else { return "N/A" }
        return String(format: "%.2fR", value)
    }

    private func formatRating(_ value: Double?) -> String {
        guard let value else { return "N/A" }
        return String(format: "%.1f / 5", value)
    }

    private func formatDuration(_ value: TimeInterval?) -> String {
        guard let value else { return "N/A" }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: value) ?? "N/A"
    }

    private func formatSegmentDetail(_ segment: TradeInsights.SegmentPerformance) -> String {
        let winRate = formatPercent(segment.winRate)
        let avgR = formatR(segment.avgR)
        return "\(segment.trades) trades • Win Rate \(winRate) • Avg \(avgR)"
    }
}

private struct InsightsBanner: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "info.circle")
            Text(text)
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    JournalInsightsView()
}
