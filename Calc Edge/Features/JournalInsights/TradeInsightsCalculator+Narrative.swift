import Foundation

extension TradeInsightsCalculator {
    func buildHighlights(
        totalTrades: Int,
        expectancy: Double?,
        profitFactor: Double?,
        bestSetup: TradeInsightSegmentPerformance?,
        worstSetup: TradeInsightSegmentPerformance?,
        followedPlanExpectancy: Double?,
        brokePlanExpectancy: Double?,
        topMistakes: [TradeInsightCountedItem],
        averageCostDrag: Double?
    ) -> [TradeInsightHighlight] {
        var highlights: [TradeInsightHighlight] = []

        appendExpectancyHighlight(expectancy, to: &highlights)
        appendSetupHighlights(bestSetup: bestSetup, worstSetup: worstSetup, to: &highlights)
        appendPlanDeltaHighlight(
            followedPlanExpectancy: followedPlanExpectancy,
            brokePlanExpectancy: brokePlanExpectancy,
            to: &highlights
        )
        appendMistakeOrProfitFactorHighlight(
            topMistakes: topMistakes,
            profitFactor: profitFactor,
            to: &highlights
        )
        appendCostDragHighlight(averageCostDrag, to: &highlights)
        appendFallbackHighlight(totalTrades: totalTrades, to: &highlights)

        return Array(highlights.prefix(5))
    }

    func buildNextReviewFocus(
        reviewCoverage: Double?,
        stopCoverage: Double?,
        exitReasonCoverage: Double?,
        followedPlanRate: Double?,
        worstSetup: TradeInsightSegmentPerformance?,
        topMistakes: [TradeInsightCountedItem]
    ) -> TradeInsightReviewFocus? {
        if (reviewCoverage ?? 1) < 0.7 {
            return TradeInsightReviewFocus(
                title: "Raise review coverage",
                detail: "The insights are limited until most closed trades have a review. Start by reviewing your latest unreviewed trades."
            )
        }

        if (stopCoverage ?? 1) < 0.8 {
            return TradeInsightReviewFocus(
                title: "Define risk more consistently",
                detail: "Add stop prices to closed trades so expectancy, R multiple, and setup quality are reliable."
            )
        }

        if (exitReasonCoverage ?? 1) < 0.8 {
            return TradeInsightReviewFocus(
                title: "Tag exit reasons",
                detail: "Exit reason coverage is thin. Tag exits to separate good profit-taking from avoidable exits."
            )
        }

        if let followedPlanRate, followedPlanRate < 0.8 {
            return TradeInsightReviewFocus(
                title: "Tighten plan adherence",
                detail: "Followed-plan rate is below 80%. Review the last broken-plan trades and turn the repeated cause into one rule."
            )
        }

        if let topMistake = topMistakes.first {
            return TradeInsightReviewFocus(
                title: "Attack \(topMistake.label)",
                detail: "This is your most common mistake tag. Make it the next review theme and write one prevention rule."
            )
        }

        if let worstSetup, (worstSetup.expectancy ?? 0) < 0 {
            return TradeInsightReviewFocus(
                title: "Reduce \(worstSetup.label) exposure",
                detail: "This setup is negative expectancy in the current sample. Pause it or add a stricter entry filter before taking the next one."
            )
        }

        return nil
    }

    private func appendExpectancyHighlight(
        _ expectancy: Double?,
        to highlights: inout [TradeInsightHighlight]
    ) {
        guard let expectancy else { return }

        highlights.append(
            TradeInsightHighlight(
                id: "expectancy",
                title: "Current Edge",
                value: formatR(expectancy),
                detail: "Average result per risk-defined trade.",
                tone: expectancy >= 0 ? .positive : .caution
            )
        )
    }

    private func appendSetupHighlights(
        bestSetup: TradeInsightSegmentPerformance?,
        worstSetup: TradeInsightSegmentPerformance?,
        to highlights: inout [TradeInsightHighlight]
    ) {
        if let bestSetup {
            highlights.append(
                TradeInsightHighlight(
                    id: "best-setup",
                    title: "Best Setup",
                    value: bestSetup.label,
                    detail: "\(bestSetup.trades) trades, \(formatR(bestSetup.expectancy)) expectancy.",
                    tone: .positive
                )
            )
        }

        if let worstSetup, (worstSetup.expectancy ?? 0) < 0 {
            highlights.append(
                TradeInsightHighlight(
                    id: "worst-setup",
                    title: "Drag",
                    value: worstSetup.label,
                    detail: "\(worstSetup.trades) trades, \(formatR(worstSetup.expectancy)) expectancy.",
                    tone: .caution
                )
            )
        }
    }

    private func appendPlanDeltaHighlight(
        followedPlanExpectancy: Double?,
        brokePlanExpectancy: Double?,
        to highlights: inout [TradeInsightHighlight]
    ) {
        guard let followedPlanExpectancy, let brokePlanExpectancy else { return }

        let delta = followedPlanExpectancy - brokePlanExpectancy
        highlights.append(
            TradeInsightHighlight(
                id: "plan-delta",
                title: "Plan Delta",
                value: formatR(delta),
                detail: "Followed-plan trades versus broken-plan trades.",
                tone: delta >= 0 ? .positive : .caution
            )
        )
    }

    private func appendMistakeOrProfitFactorHighlight(
        topMistakes: [TradeInsightCountedItem],
        profitFactor: Double?,
        to highlights: inout [TradeInsightHighlight]
    ) {
        if let topMistake = topMistakes.first {
            highlights.append(
                TradeInsightHighlight(
                    id: "top-mistake",
                    title: "Main Mistake",
                    value: topMistake.label,
                    detail: "\(topMistake.count) tagged reviews.",
                    tone: .caution
                )
            )
        } else if let profitFactor {
            highlights.append(
                TradeInsightHighlight(
                    id: "profit-factor",
                    title: "Profit Factor",
                    value: formatProfitFactor(profitFactor),
                    detail: "Gross R winners divided by gross R losers.",
                    tone: profitFactor >= 1 ? .positive : .caution
                )
            )
        }
    }

    private func appendCostDragHighlight(
        _ averageCostDrag: Double?,
        to highlights: inout [TradeInsightHighlight]
    ) {
        guard let averageCostDrag else { return }

        highlights.append(
            TradeInsightHighlight(
                id: "cost-drag",
                title: "Avg Cost Drag",
                value: formatNumber(averageCostDrag),
                detail: "Average commissions plus slippage on closed trades.",
                tone: .neutral
            )
        )
    }

    private func appendFallbackHighlight(
        totalTrades: Int,
        to highlights: inout [TradeInsightHighlight]
    ) {
        guard highlights.isEmpty && totalTrades > 0 else { return }

        highlights.append(
            TradeInsightHighlight(
                id: "data-needed",
                title: "Insight Readiness",
                value: "\(totalTrades) trades",
                detail: "Close trades and add prices, stops, and reviews to unlock stronger readouts.",
                tone: .neutral
            )
        )
    }

    private func formatR(_ value: Double?) -> String {
        guard let value else { return "N/A" }
        return String(format: "%.2fR", value)
    }

    private func formatProfitFactor(_ value: Double?) -> String {
        guard let value else { return "N/A" }
        guard value.isFinite else { return "Inf" }
        return String(format: "%.2f", value)
    }

    private func formatNumber(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}
