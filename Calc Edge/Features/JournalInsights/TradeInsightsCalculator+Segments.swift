import Foundation

extension TradeInsightsCalculator {
    func segmentSummary(from pricedTrades: [Trade]) -> TradeInsightSegmentSummary {
        let segments = buildSegments(from: pricedTrades)
        let filteredSegments = segments.filter { $0.trades >= minSampleSize && $0.label != "Unspecified" }
        let setupSegments = filteredSegments.filter { $0.category == "Setup" }

        return TradeInsightSegmentSummary(
            bestSetup: setupSegments.sorted(by: sortStrengths).first,
            worstSetup: setupSegments.sorted(by: sortWeaknesses).first,
            edgeMapSegments: filteredSegments.sorted(by: sortStrengths),
            performanceByInstrument: segmentsForCategory("Instrument", in: segments),
            performanceByDirection: segmentsForCategory("Direction", in: segments),
            performanceByAccount: segmentsForCategory("Account", in: segments),
            strengths: Array(filteredSegments.sorted(by: sortStrengths).prefix(3)),
            weaknesses: Array(filteredSegments.sorted(by: sortWeaknesses).prefix(3))
        )
    }

    func topMistakeItems(from reviews: [TradeReview]) -> [TradeInsightCountedItem] {
        let mistakes = reviews.compactMap { $0.mistakeType?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let grouped = Dictionary(grouping: mistakes, by: { $0 })
        let total = mistakes.count

        return grouped
            .map { label, values in
                TradeInsightCountedItem(
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

    func exitReasonItems(from trades: [Trade]) -> [TradeInsightCountedItem] {
        let reasons = trades.compactMap(\.exitReason)
        let grouped = Dictionary(grouping: reasons, by: { $0 })
        let total = reasons.count

        return grouped
            .map { reason, values in
                TradeInsightCountedItem(
                    id: "ExitReason:\(reason.rawValue)",
                    label: reason.rawValue.capitalized,
                    count: values.count,
                    percentage: rate(values.count, total)
                )
            }
            .sorted { $0.count > $1.count }
            .map { $0 }
    }

    private func buildSegments(from trades: [Trade]) -> [TradeInsightSegmentPerformance] {
        var segments: [TradeInsightSegmentPerformance] = []

        segments += segmentPerformance(for: trades, category: "Strategy") { $0.strategyName }
        segments += segmentPerformance(for: trades, category: "Setup") { $0.setupType }
        segments += segmentPerformance(for: trades, category: "Timeframe") { $0.timeframe }
        segments += segmentPerformance(for: trades, category: "Instrument") { $0.instrument.rawValue.capitalized }
        segments += segmentPerformance(for: trades, category: "Direction") { $0.direction.rawValue.capitalized }
        segments += segmentPerformance(for: trades, category: "Account") { $0.account }
        segments += reviewSegments(from: trades)
        segments += contextSegments(from: trades)
        segments += segmentPerformance(for: trades, category: "Confidence") {
            "Score \($0.confidenceScore)"
        }

        return segments
    }

    private func reviewSegments(from trades: [Trade]) -> [TradeInsightSegmentPerformance] {
        segmentPerformance(for: trades.filter { $0.review != nil }, category: "Emotion") {
            $0.review?.emotionalState.rawValue.capitalized
        }
    }

    private func contextSegments(from trades: [Trade]) -> [TradeInsightSegmentPerformance] {
        let contextTrades = trades.filter { $0.context != nil }

        return segmentPerformance(for: contextTrades, category: "Market Regime") {
            $0.context?.marketRegime.rawValue.capitalized
        } + segmentPerformance(for: contextTrades, category: "Time of Day") {
            $0.context?.timeOfDayTag
        }
    }

    private func segmentPerformance(
        for trades: [Trade],
        category: String,
        label: (Trade) -> String?
    ) -> [TradeInsightSegmentPerformance] {
        let grouped = Dictionary(grouping: trades) { trade in
            cleanSegmentLabel(label(trade))
        }

        return grouped.map { label, trades in
            buildSegmentPerformance(category: category, label: label, trades: trades)
        }
    }

    private func buildSegmentPerformance(
        category: String,
        label: String,
        trades: [Trade]
    ) -> TradeInsightSegmentPerformance {
        let winCount = wins(in: trades)
        let rMultiples = trades.compactMap { rMultiple(for: $0) }
        let winningRMultiples = rMultiples.filter { $0 > 0 }
        let losingRMultiples = rMultiples.filter { $0 < 0 }

        return TradeInsightSegmentPerformance(
            id: "\(category):\(label)",
            category: category,
            label: label,
            trades: trades.count,
            wins: winCount,
            winRate: rate(winCount, trades.count),
            expectancy: average(rMultiples),
            averageWinner: average(winningRMultiples),
            averageLoser: average(losingRMultiples),
            profitFactor: profitFactor(for: rMultiples)
        )
    }

    private func segmentsForCategory(
        _ category: String,
        in segments: [TradeInsightSegmentPerformance]
    ) -> [TradeInsightSegmentPerformance] {
        segments
            .filter { $0.category == category && $0.label != "Unspecified" && $0.trades >= minSampleSize }
            .sorted(by: sortStrengths)
    }

    private func cleanSegmentLabel(_ label: String?) -> String {
        let trimmedLabel = label?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedLabel?.isEmpty == false ? trimmedLabel! : "Unspecified"
    }

    private func sortStrengths(
        _ lhs: TradeInsightSegmentPerformance,
        _ rhs: TradeInsightSegmentPerformance
    ) -> Bool {
        let lhsExpectancy = lhs.expectancy ?? -Double.greatestFiniteMagnitude
        let rhsExpectancy = rhs.expectancy ?? -Double.greatestFiniteMagnitude
        if lhsExpectancy != rhsExpectancy {
            return lhsExpectancy > rhsExpectancy
        }

        if lhs.winRate != rhs.winRate {
            return (lhs.winRate ?? 0) > (rhs.winRate ?? 0)
        }

        if lhs.trades != rhs.trades {
            return lhs.trades > rhs.trades
        }

        if lhs.category != rhs.category {
            return lhs.category < rhs.category
        }

        return lhs.label.localizedStandardCompare(rhs.label) == .orderedAscending
    }

    private func sortWeaknesses(
        _ lhs: TradeInsightSegmentPerformance,
        _ rhs: TradeInsightSegmentPerformance
    ) -> Bool {
        let lhsExpectancy = lhs.expectancy ?? Double.greatestFiniteMagnitude
        let rhsExpectancy = rhs.expectancy ?? Double.greatestFiniteMagnitude
        if lhsExpectancy != rhsExpectancy {
            return lhsExpectancy < rhsExpectancy
        }

        if lhs.winRate != rhs.winRate {
            return (lhs.winRate ?? 0) < (rhs.winRate ?? 0)
        }

        if lhs.trades != rhs.trades {
            return lhs.trades > rhs.trades
        }

        if lhs.category != rhs.category {
            return lhs.category < rhs.category
        }

        return lhs.label.localizedStandardCompare(rhs.label) == .orderedAscending
    }
}
