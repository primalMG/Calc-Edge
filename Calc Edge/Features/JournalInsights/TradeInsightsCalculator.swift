import Foundation

struct TradeInsightsCalculator {
    let trades: [Trade]
    let minSampleSize: Int

    init(trades: [Trade], minSampleSize: Int = 3) {
        self.trades = trades
        self.minSampleSize = max(1, minSampleSize)
    }

    func calculate() -> TradeInsights {
        let totalTrades = trades.count
        let closedTrades = trades.filter { $0.closedAt != nil }
        let pricedTrades = closedTrades.filter { hasEntryAndExit($0) }
        let riskDefinedTrades = pricedTrades.filter { rMultiple(for: $0) != nil }
        let reviewTrades = trades.filter { $0.review != nil }
        let rMultiples = riskDefinedTrades.compactMap { rMultiple(for: $0) }
        let winningRMultiples = rMultiples.filter { $0 > 0 }
        let losingRMultiples = rMultiples.filter { $0 < 0 }

        let winRate = rate(wins(in: pricedTrades), pricedTrades.count)
        let averageWinner = average(winningRMultiples)
        let averageLoser = average(losingRMultiples)
        let expectancy = average(rMultiples)
        let profitFactor = profitFactor(for: rMultiples)
        let averageHoldTime = averageHoldDuration(in: closedTrades)

        let aPlusTrades = riskDefinedTrades.filter { $0.isAPlusSetup }
        let nonAPlusTrades = riskDefinedTrades.filter { !$0.isAPlusSetup }

        let aPlusWinRate = rate(wins(in: aPlusTrades), aPlusTrades.count)
        let nonAPlusWinRate = rate(wins(in: nonAPlusTrades), nonAPlusTrades.count)
        let aPlusExpectancy = average(aPlusTrades.compactMap { rMultiple(for: $0) })
        let nonAPlusExpectancy = average(nonAPlusTrades.compactMap { rMultiple(for: $0) })

        let reviews = reviewTrades.compactMap { $0.review }
        let followedPlanRate = rate(reviews.filter { $0.followedPlan }.count, reviews.count)
        let wouldRetakeRate = rate(reviews.filter { $0.wouldRetake }.count, reviews.count)
        let entryQualityAverage = average(reviews.map { Double($0.entryQuality) })
        let exitQualityAverage = average(reviews.map { Double($0.exitQuality) })
        let followedPlanExpectancy = average(
            riskDefinedTrades
                .filter { $0.review?.followedPlan == true }
                .compactMap { rMultiple(for: $0) }
        )
        let brokePlanExpectancy = average(
            riskDefinedTrades
                .filter { $0.review?.followedPlan == false }
                .compactMap { rMultiple(for: $0) }
        )

        let targetHitRate = rate(closedTrades.filter { $0.exitReason == .targetHit }.count, closedTrades.count)
        let averagePlannedR = average(riskDefinedTrades.compactMap { plannedR(for: $0) })
        let averageMAE = average(trades.compactMap { decimalToDouble($0.mae) })
        let averageMFE = average(trades.compactMap { decimalToDouble($0.mfe) })
        let averageCostDrag = average(closedTrades.compactMap { costDrag(for: $0) })
        let highConfidenceLosers = riskDefinedTrades.filter {
            $0.confidenceScore >= 4 && (rMultiple(for: $0) ?? 0) < 0
        }.count
        let lowConfidenceWinners = riskDefinedTrades.filter {
            $0.confidenceScore <= 2 && (rMultiple(for: $0) ?? 0) > 0
        }.count

        let segments = buildSegments(from: pricedTrades)
        let filteredSegments = segments.filter { $0.trades >= minSampleSize && $0.label != "Unspecified" }
        let setupSegments = filteredSegments.filter { $0.category == "Setup" }
        let bestSetup = setupSegments.sorted(by: sortStrengths).first
        let worstSetup = setupSegments.sorted(by: sortWeaknesses).first
        let edgeMapSegments = filteredSegments.sorted(by: sortStrengths)
        let performanceByInstrument = segmentsForCategory("Instrument", in: segments)
        let performanceByDirection = segmentsForCategory("Direction", in: segments)
        let performanceByAccount = segmentsForCategory("Account", in: segments)

        let strengths = Array(filteredSegments.sorted(by: sortStrengths).prefix(3))
        let weaknesses = Array(filteredSegments.sorted(by: sortWeaknesses).prefix(3))

        let topMistakes = topMistakeItems(from: reviews)
        let exitReasons = exitReasonItems(from: closedTrades)

        let reviewCoverage = rate(reviewTrades.count, totalTrades)
        let stopCoverage = rate(pricedTrades.filter { $0.stopPrice != nil }.count, pricedTrades.count)
        let exitReasonCoverage = rate(closedTrades.filter { $0.exitReason != nil }.count, closedTrades.count)
        let highlights = buildHighlights(
            totalTrades: totalTrades,
            expectancy: expectancy,
            profitFactor: profitFactor,
            bestSetup: bestSetup,
            worstSetup: worstSetup,
            followedPlanExpectancy: followedPlanExpectancy,
            brokePlanExpectancy: brokePlanExpectancy,
            topMistakes: topMistakes,
            averageCostDrag: averageCostDrag
        )
        let nextReviewFocus = buildNextReviewFocus(
            reviewCoverage: reviewCoverage,
            stopCoverage: stopCoverage,
            exitReasonCoverage: exitReasonCoverage,
            followedPlanRate: followedPlanRate,
            worstSetup: worstSetup,
            topMistakes: topMistakes
        )

        return TradeInsights(
            totalTrades: totalTrades,
            closedTrades: closedTrades.count,
            pricedTrades: pricedTrades.count,
            riskDefinedTrades: riskDefinedTrades.count,
            winRate: winRate,
            averageWinner: averageWinner,
            averageLoser: averageLoser,
            expectancy: expectancy,
            profitFactor: profitFactor,
            averageHoldTime: averageHoldTime,
            aPlusWinRate: aPlusWinRate,
            nonAPlusWinRate: nonAPlusWinRate,
            aPlusExpectancy: aPlusExpectancy,
            nonAPlusExpectancy: nonAPlusExpectancy,
            followedPlanExpectancy: followedPlanExpectancy,
            brokePlanExpectancy: brokePlanExpectancy,
            followedPlanRate: followedPlanRate,
            wouldRetakeRate: wouldRetakeRate,
            entryQualityAverage: entryQualityAverage,
            exitQualityAverage: exitQualityAverage,
            targetHitRate: targetHitRate,
            averagePlannedR: averagePlannedR,
            averageMAE: averageMAE,
            averageMFE: averageMFE,
            averageCostDrag: averageCostDrag,
            highConfidenceLosers: highConfidenceLosers,
            lowConfidenceWinners: lowConfidenceWinners,
            highlights: highlights,
            nextReviewFocus: nextReviewFocus,
            bestSetup: bestSetup,
            worstSetup: worstSetup,
            edgeMapSegments: edgeMapSegments,
            performanceByInstrument: performanceByInstrument,
            performanceByDirection: performanceByDirection,
            performanceByAccount: performanceByAccount,
            strengths: strengths,
            weaknesses: weaknesses,
            topMistakes: topMistakes,
            exitReasons: exitReasons,
            reviewCoverage: reviewCoverage,
            stopCoverage: stopCoverage,
            exitReasonCoverage: exitReasonCoverage
        )
    }

    private func buildSegments(from trades: [Trade]) -> [TradeInsights.SegmentPerformance] {
        var segments: [TradeInsights.SegmentPerformance] = []

        segments += segmentPerformance(for: trades, category: "Strategy") { $0.strategyName }
        segments += segmentPerformance(for: trades, category: "Setup") { $0.setupType }
        segments += segmentPerformance(for: trades, category: "Timeframe") { $0.timeframe }
        segments += segmentPerformance(for: trades, category: "Instrument") { $0.instrument.rawValue.capitalized }
        segments += segmentPerformance(for: trades, category: "Direction") { $0.direction.rawValue.capitalized }
        segments += segmentPerformance(for: trades, category: "Account") { $0.account }

        let emotionalTrades = trades.filter { $0.review != nil }
        segments += segmentPerformance(for: emotionalTrades, category: "Emotion") {
            $0.review?.emotionalState.rawValue.capitalized
        }

        let contextTrades = trades.filter { $0.context != nil }
        segments += segmentPerformance(for: contextTrades, category: "Market Regime") {
            $0.context?.marketRegime.rawValue.capitalized
        }
        segments += segmentPerformance(for: contextTrades, category: "Time of Day") {
            $0.context?.timeOfDayTag
        }
        segments += segmentPerformance(for: trades, category: "Confidence") {
            "Score \($0.confidenceScore)"
        }

        return segments
    }

    private func segmentPerformance(
        for trades: [Trade],
        category: String,
        label: (Trade) -> String?
    ) -> [TradeInsights.SegmentPerformance] {
        let grouped = Dictionary(grouping: trades) { trade in
            let rawLabel = label(trade)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return rawLabel?.isEmpty == false ? rawLabel! : "Unspecified"
        }

        return grouped.map { label, trades in
            let winCount = wins(in: trades)
            let winRate = rate(winCount, trades.count)
            let rMultiples = trades.compactMap { rMultiple(for: $0) }
            let winningRMultiples = rMultiples.filter { $0 > 0 }
            let losingRMultiples = rMultiples.filter { $0 < 0 }

            return TradeInsights.SegmentPerformance(
                id: "\(category):\(label)",
                category: category,
                label: label,
                trades: trades.count,
                wins: winCount,
                winRate: winRate,
                expectancy: average(rMultiples),
                averageWinner: average(winningRMultiples),
                averageLoser: average(losingRMultiples),
                profitFactor: profitFactor(for: rMultiples)
            )
        }
    }

    private func segmentsForCategory(
        _ category: String,
        in segments: [TradeInsights.SegmentPerformance]
    ) -> [TradeInsights.SegmentPerformance] {
        segments
            .filter { $0.category == category && $0.label != "Unspecified" && $0.trades >= minSampleSize }
            .sorted(by: sortStrengths)
    }

    private func topMistakeItems(from reviews: [TradeReview]) -> [TradeInsights.CountedItem] {
        let mistakes = reviews.compactMap { $0.mistakeType?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let grouped = Dictionary(grouping: mistakes, by: { $0 })
        let total = mistakes.count

        return grouped
            .map { label, values in
                TradeInsights.CountedItem(
                    id: "Mistake:\(label)",
                    label: label,
                    count: values.count,
                    percentage: rate(values.count, total)
                )
            }
            .sorted { $0.count > $1.count }
            .prefix(5)
            .map { $0 }
    }

    private func exitReasonItems(from trades: [Trade]) -> [TradeInsights.CountedItem] {
        let reasons = trades.compactMap { $0.exitReason }
        let grouped = Dictionary(grouping: reasons, by: { $0 })
        let total = reasons.count

        return grouped
            .map { reason, values in
                TradeInsights.CountedItem(
                    id: "ExitReason:\(reason.rawValue)",
                    label: reason.rawValue.capitalized,
                    count: values.count,
                    percentage: rate(values.count, total)
                )
            }
            .sorted { $0.count > $1.count }
            .map { $0 }
    }

    private func hasEntryAndExit(_ trade: Trade) -> Bool {
        trade.entryPrice != nil && trade.exitPrice != nil
    }

    private func wins(in trades: [Trade]) -> Int {
        trades.filter { (priceMove(for: $0) ?? 0) > 0 }.count
    }

    private func priceMove(for trade: Trade) -> Double? {
        guard let entry = decimalToDouble(trade.entryPrice),
              let exit = decimalToDouble(trade.exitPrice) else {
            return nil
        }

        switch trade.direction {
        case .long:
            return exit - entry
        case .short:
            return entry - exit
        }
    }

    private func rMultiple(for trade: Trade) -> Double? {
        guard let entry = decimalToDouble(trade.entryPrice),
              let exit = decimalToDouble(trade.exitPrice),
              let stop = decimalToDouble(trade.stopPrice) else {
            return nil
        }

        let risk: Double
        let reward: Double

        switch trade.direction {
        case .long:
            risk = entry - stop
            reward = exit - entry
        case .short:
            risk = stop - entry
            reward = entry - exit
        }

        guard risk > 0 else { return nil }
        return reward / risk
    }

    private func plannedR(for trade: Trade) -> Double? {
        guard let entry = decimalToDouble(trade.entryPrice),
              let target = decimalToDouble(trade.targetPrice),
              let stop = decimalToDouble(trade.stopPrice) else {
            return nil
        }

        let risk: Double
        let reward: Double

        switch trade.direction {
        case .long:
            risk = entry - stop
            reward = target - entry
        case .short:
            risk = stop - entry
            reward = entry - target
        }

        guard risk > 0 else { return nil }
        return reward / risk
    }

    private func costDrag(for trade: Trade) -> Double? {
        let commission = decimalToDouble(trade.commissions) ?? 0
        let slippage = decimalToDouble(trade.slippage) ?? 0
        let total = commission + slippage
        return total > 0 ? total : nil
    }

    private func averageHoldDuration(in trades: [Trade]) -> TimeInterval? {
        let durations = trades.compactMap { trade -> TimeInterval? in
            guard let closedAt = trade.closedAt else { return nil }
            return closedAt.timeIntervalSince(trade.openedAt)
        }

        guard !durations.isEmpty else { return nil }
        return durations.reduce(0, +) / Double(durations.count)
    }

    private func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private func profitFactor(for values: [Double]) -> Double? {
        let grossProfit = values.filter { $0 > 0 }.reduce(0, +)
        let grossLoss = abs(values.filter { $0 < 0 }.reduce(0, +))

        guard grossProfit > 0 || grossLoss > 0 else { return nil }
        guard grossLoss > 0 else { return .infinity }
        return grossProfit / grossLoss
    }

    private func rate(_ part: Int, _ total: Int) -> Double? {
        guard total > 0 else { return nil }
        return Double(part) / Double(total)
    }

    private func decimalToDouble(_ value: Decimal?) -> Double? {
        guard let value else { return nil }
        return NSDecimalNumber(decimal: value).doubleValue
    }

    private func buildHighlights(
        totalTrades: Int,
        expectancy: Double?,
        profitFactor: Double?,
        bestSetup: TradeInsights.SegmentPerformance?,
        worstSetup: TradeInsights.SegmentPerformance?,
        followedPlanExpectancy: Double?,
        brokePlanExpectancy: Double?,
        topMistakes: [TradeInsights.CountedItem],
        averageCostDrag: Double?
    ) -> [TradeInsights.Highlight] {
        var highlights: [TradeInsights.Highlight] = []

        if let expectancy {
            highlights.append(
                TradeInsights.Highlight(
                    id: "expectancy",
                    title: "Current Edge",
                    value: formatR(expectancy),
                    detail: "Average result per risk-defined trade.",
                    tone: expectancy >= 0 ? .positive : .caution
                )
            )
        }

        if let bestSetup {
            highlights.append(
                TradeInsights.Highlight(
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
                TradeInsights.Highlight(
                    id: "worst-setup",
                    title: "Drag",
                    value: worstSetup.label,
                    detail: "\(worstSetup.trades) trades, \(formatR(worstSetup.expectancy)) expectancy.",
                    tone: .caution
                )
            )
        }

        if let followedPlanExpectancy, let brokePlanExpectancy {
            let delta = followedPlanExpectancy - brokePlanExpectancy
            highlights.append(
                TradeInsights.Highlight(
                    id: "plan-delta",
                    title: "Plan Delta",
                    value: formatR(delta),
                    detail: "Followed-plan trades versus broken-plan trades.",
                    tone: delta >= 0 ? .positive : .caution
                )
            )
        }

        if let topMistake = topMistakes.first {
            highlights.append(
                TradeInsights.Highlight(
                    id: "top-mistake",
                    title: "Main Mistake",
                    value: topMistake.label,
                    detail: "\(topMistake.count) tagged reviews.",
                    tone: .caution
                )
            )
        } else if let profitFactor {
            highlights.append(
                TradeInsights.Highlight(
                    id: "profit-factor",
                    title: "Profit Factor",
                    value: formatProfitFactor(profitFactor),
                    detail: "Gross R winners divided by gross R losers.",
                    tone: profitFactor >= 1 ? .positive : .caution
                )
            )
        }

        if let averageCostDrag {
            highlights.append(
                TradeInsights.Highlight(
                    id: "cost-drag",
                    title: "Avg Cost Drag",
                    value: formatNumber(averageCostDrag),
                    detail: "Average commissions plus slippage on closed trades.",
                    tone: .neutral
                )
            )
        }

        if highlights.isEmpty && totalTrades > 0 {
            highlights.append(
                TradeInsights.Highlight(
                    id: "data-needed",
                    title: "Insight Readiness",
                    value: "\(totalTrades) trades",
                    detail: "Close trades and add prices, stops, and reviews to unlock stronger readouts.",
                    tone: .neutral
                )
            )
        }

        return Array(highlights.prefix(5))
    }

    private func buildNextReviewFocus(
        reviewCoverage: Double?,
        stopCoverage: Double?,
        exitReasonCoverage: Double?,
        followedPlanRate: Double?,
        worstSetup: TradeInsights.SegmentPerformance?,
        topMistakes: [TradeInsights.CountedItem]
    ) -> TradeInsights.ReviewFocus? {
        if (reviewCoverage ?? 1) < 0.7 {
            return TradeInsights.ReviewFocus(
                title: "Raise review coverage",
                detail: "The insights are limited until most closed trades have a review. Start by reviewing your latest unreviewed trades."
            )
        }

        if (stopCoverage ?? 1) < 0.8 {
            return TradeInsights.ReviewFocus(
                title: "Define risk more consistently",
                detail: "Add stop prices to closed trades so expectancy, R multiple, and setup quality are reliable."
            )
        }

        if (exitReasonCoverage ?? 1) < 0.8 {
            return TradeInsights.ReviewFocus(
                title: "Tag exit reasons",
                detail: "Exit reason coverage is thin. Tag exits to separate good profit-taking from avoidable exits."
            )
        }

        if let followedPlanRate, followedPlanRate < 0.8 {
            return TradeInsights.ReviewFocus(
                title: "Tighten plan adherence",
                detail: "Followed-plan rate is below 80%. Review the last broken-plan trades and turn the repeated cause into one rule."
            )
        }

        if let topMistake = topMistakes.first {
            return TradeInsights.ReviewFocus(
                title: "Attack \(topMistake.label)",
                detail: "This is your most common mistake tag. Make it the next review theme and write one prevention rule."
            )
        }

        if let worstSetup, (worstSetup.expectancy ?? 0) < 0 {
            return TradeInsights.ReviewFocus(
                title: "Reduce \(worstSetup.label) exposure",
                detail: "This setup is negative expectancy in the current sample. Pause it or add a stricter entry filter before taking the next one."
            )
        }

        return nil
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

    private func sortStrengths(
        _ lhs: TradeInsights.SegmentPerformance,
        _ rhs: TradeInsights.SegmentPerformance
    ) -> Bool {
        let lhsExpectancy = lhs.expectancy ?? -Double.greatestFiniteMagnitude
        let rhsExpectancy = rhs.expectancy ?? -Double.greatestFiniteMagnitude
        if lhsExpectancy != rhsExpectancy {
            return lhsExpectancy > rhsExpectancy
        }

        if lhs.winRate != rhs.winRate {
            return (lhs.winRate ?? 0) > (rhs.winRate ?? 0)
        }

        return lhs.trades > rhs.trades
    }

    private func sortWeaknesses(
        _ lhs: TradeInsights.SegmentPerformance,
        _ rhs: TradeInsights.SegmentPerformance
    ) -> Bool {
        let lhsExpectancy = lhs.expectancy ?? Double.greatestFiniteMagnitude
        let rhsExpectancy = rhs.expectancy ?? Double.greatestFiniteMagnitude
        if lhsExpectancy != rhsExpectancy {
            return lhsExpectancy < rhsExpectancy
        }

        if lhs.winRate != rhs.winRate {
            return (lhs.winRate ?? 0) < (rhs.winRate ?? 0)
        }

        return lhs.trades > rhs.trades
    }
}
