import SwiftUI

struct JournalInsightsOverviewSection: View {
    let insights: TradeInsights
    let columns: [GridItem]

    var body: some View {
        InfoSection(title: "Overview") {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
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
                InfoStatCard(title: "Avg Hold", value: JournalInsightsFormatting.duration(insights.averageHoldTime))
                InfoStatCard(title: "Closed Trades", value: "\(insights.closedTrades)", subtitle: "\(insights.totalTrades) total")
            }
        }
    }
}

struct JournalInsightsEdgeMapSection: View {
    let insights: TradeInsights
    let minSampleSize: Int
    @Binding var selectedCategory: String

    private var edgeCategories: [String] {
        let categories = Set(insights.edgeMapSegments.map(\.category)).sorted()
        return categories.isEmpty ? ["All"] : ["All"] + categories
    }

    private var selectedSegments: [TradeInsights.SegmentPerformance] {
        if selectedCategory == "All" {
            return insights.edgeMapSegments
        }

        return insights.edgeMapSegments.filter { $0.category == selectedCategory }
    }

    var body: some View {
        InfoSection(title: "Edge Map") {
            VStack(alignment: .leading, spacing: 12) {
                if edgeCategories.count > 1 {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(edgeCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                }

                if selectedSegments.isEmpty {
                    Text("Not enough categorized trades yet. Add at least \(minSampleSize) trades per category.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(selectedSegments.prefix(8)) { segment in
                        EdgeMapRow(segment: segment)
                    }
                }
            }
            .onChange(of: edgeCategories) { _, categories in
                if !categories.contains(selectedCategory) {
                    selectedCategory = categories.first ?? "All"
                }
            }
        }
    }
}

struct JournalInsightsStrengthsDragSection: View {
    let insights: TradeInsights
    let minSampleSize: Int

    var body: some View {
        InfoSection(title: "Strengths & Drag") {
            if insights.strengths.isEmpty && insights.weaknesses.isEmpty {
                Text("Not enough categorized trades yet. Add at least \(minSampleSize) trades per category.")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    strengthsContent
                    weaknessesContent
                }
            }
        }
    }

    @ViewBuilder
    private var strengthsContent: some View {
        if !insights.strengths.isEmpty {
            Text("Where You Excel")
                .font(.subheadline)
                .fontWeight(.semibold)

            ForEach(insights.strengths) { segment in
                InfoRow(
                    title: "\(segment.category): \(segment.label)",
                    detail: JournalInsightsFormatting.segmentDetail(segment)
                )
            }
        }
    }

    @ViewBuilder
    private var weaknessesContent: some View {
        if !insights.weaknesses.isEmpty {
            Text("Needs Attention")
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.top, 4)

            ForEach(insights.weaknesses) { segment in
                InfoRow(
                    title: "\(segment.category): \(segment.label)",
                    detail: JournalInsightsFormatting.segmentDetail(segment)
                )
            }
        }
    }
}

struct JournalInsightsRiskEfficiencySection: View {
    let insights: TradeInsights
    let columns: [GridItem]

    var body: some View {
        InfoSection(title: "Risk Efficiency") {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                InfoStatCard(title: "Target Hit Rate", value: JournalInsightsFormatting.percent(insights.targetHitRate))
                InfoStatCard(title: "Avg Planned R", value: JournalInsightsFormatting.rMultiple(insights.averagePlannedR))
                InfoStatCard(title: "Avg MAE", value: JournalInsightsFormatting.number(insights.averageMAE))
                InfoStatCard(title: "Avg MFE", value: JournalInsightsFormatting.number(insights.averageMFE))
                InfoStatCard(title: "Avg Cost Drag", value: JournalInsightsFormatting.number(insights.averageCostDrag))
            }
        }
    }
}

struct JournalInsightsProcessQualitySection: View {
    let insights: TradeInsights
    let columns: [GridItem]

    private var planDelta: Double? {
        guard let followed = insights.followedPlanExpectancy,
              let broke = insights.brokePlanExpectancy else {
            return nil
        }

        return followed - broke
    }

    var body: some View {
        InfoSection(title: "Process Quality") {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                InfoStatCard(
                    title: "A+ Expectancy",
                    value: JournalInsightsFormatting.rMultiple(insights.aPlusExpectancy),
                    accentColor: JournalInsightsFormatting.valueColor(for: insights.aPlusExpectancy)
                )
                InfoStatCard(
                    title: "Non-A+ Expectancy",
                    value: JournalInsightsFormatting.rMultiple(insights.nonAPlusExpectancy),
                    accentColor: JournalInsightsFormatting.valueColor(for: insights.nonAPlusExpectancy)
                )
                InfoStatCard(
                    title: "Plan Delta",
                    value: JournalInsightsFormatting.rMultiple(planDelta),
                    accentColor: JournalInsightsFormatting.valueColor(for: planDelta)
                )
                InfoStatCard(title: "Followed Plan", value: JournalInsightsFormatting.percent(insights.followedPlanRate))
                InfoStatCard(title: "Would Retake", value: JournalInsightsFormatting.percent(insights.wouldRetakeRate))
                InfoStatCard(title: "Entry Quality", value: JournalInsightsFormatting.rating(insights.entryQualityAverage))
                InfoStatCard(title: "Exit Quality", value: JournalInsightsFormatting.rating(insights.exitQualityAverage))
                InfoStatCard(title: "High-Confidence Losers", value: "\(insights.highConfidenceLosers)")
                InfoStatCard(title: "Low-Confidence Winners", value: "\(insights.lowConfidenceWinners)")
            }
        }
    }
}

struct JournalInsightsDataQualitySection: View {
    let insights: TradeInsights
    let columns: [GridItem]

    var body: some View {
        InfoSection(title: "Data Quality") {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                InfoStatCard(title: "Review Coverage", value: JournalInsightsFormatting.percent(insights.reviewCoverage))
                InfoStatCard(title: "Stop Coverage", value: JournalInsightsFormatting.percent(insights.stopCoverage))
                InfoStatCard(title: "Exit Reason Coverage", value: JournalInsightsFormatting.percent(insights.exitReasonCoverage))
            }
        }
    }
}

struct JournalInsightsCountedItemsSection: View {
    let title: String
    let emptyText: String
    let items: [TradeInsights.CountedItem]

    var body: some View {
        InfoSection(title: title) {
            if items.isEmpty {
                Text(emptyText)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items) { item in
                    InfoRow(
                        title: item.label,
                        detail: "\(item.count) trades • \(JournalInsightsFormatting.percent(item.percentage))"
                    )
                }
            }
        }
    }
}
