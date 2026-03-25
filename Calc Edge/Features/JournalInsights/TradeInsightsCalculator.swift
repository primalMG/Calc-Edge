import Foundation

struct TradeInsights {
    struct SegmentPerformance: Identifiable {
        let id: String
        let category: String
        let label: String
        let trades: Int
        let wins: Int
        let winRate: Double?
        let expectancy: Double?
        let averageWinner: Double?
        let averageLoser: Double?
        let profitFactor: Double?
    }

    struct CountedItem: Identifiable {
        let id: String
        let label: String
        let count: Int
        let percentage: Double?
    }

    let totalTrades: Int
    let closedTrades: Int
    let pricedTrades: Int
    let riskDefinedTrades: Int
    let winRate: Double?
    let averageWinner: Double?
    let averageLoser: Double?
    let expectancy: Double?
    let profitFactor: Double?
    let averageHoldTime: TimeInterval?
    let aPlusWinRate: Double?
    let nonAPlusWinRate: Double?

    let followedPlanRate: Double?
    let wouldRetakeRate: Double?
    let entryQualityAverage: Double?
    let exitQualityAverage: Double?

    let bestSetup: SegmentPerformance?
    let worstSetup: SegmentPerformance?
    let performanceByInstrument: [SegmentPerformance]
    let performanceByDirection: [SegmentPerformance]
    let performanceByAccount: [SegmentPerformance]
    let strengths: [SegmentPerformance]
    let weaknesses: [SegmentPerformance]
    let topMistakes: [CountedItem]
    let exitReasons: [CountedItem]

    let reviewCoverage: Double?
    let stopCoverage: Double?
    let exitReasonCoverage: Double?
}

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

        let reviews = reviewTrades.compactMap { $0.review }
        let followedPlanRate = rate(reviews.filter { $0.followedPlan }.count, reviews.count)
        let wouldRetakeRate = rate(reviews.filter { $0.wouldRetake }.count, reviews.count)
        let entryQualityAverage = average(reviews.map { Double($0.entryQuality) })
        let exitQualityAverage = average(reviews.map { Double($0.exitQuality) })

        let segments = buildSegments(from: pricedTrades)
        let filteredSegments = segments.filter { $0.trades >= minSampleSize && $0.label != "Unspecified" }
        let setupSegments = filteredSegments.filter { $0.category == "Setup" }
        let bestSetup = setupSegments.sorted(by: sortStrengths).first
        let worstSetup = setupSegments.sorted(by: sortWeaknesses).first
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
            followedPlanRate: followedPlanRate,
            wouldRetakeRate: wouldRetakeRate,
            entryQualityAverage: entryQualityAverage,
            exitQualityAverage: exitQualityAverage,
            bestSetup: bestSetup,
            worstSetup: worstSetup,
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
