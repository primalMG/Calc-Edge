import Foundation

extension TradeInsightsCalculator {
    func tradeBuckets() -> TradeInsightTradeBuckets {
        let closedTrades = trades.filter { $0.closedAt != nil }
        let pricedTrades = closedTrades.filter { hasEntryAndExit($0) }
        let riskDefinedTrades = pricedTrades.filter { rMultiple(for: $0) != nil }
        let reviewTrades = trades.filter { $0.review != nil }

        return TradeInsightTradeBuckets(
            totalTrades: trades.count,
            closedTrades: closedTrades,
            pricedTrades: pricedTrades,
            riskDefinedTrades: riskDefinedTrades,
            reviewTrades: reviewTrades,
            reviews: reviewTrades.compactMap(\.review)
        )
    }

    func outcomeMetrics(from buckets: TradeInsightTradeBuckets) -> TradeInsightOutcomeMetrics {
        let rMultiples = buckets.riskDefinedTrades.compactMap { rMultiple(for: $0) }
        let winningRMultiples = rMultiples.filter { $0 > 0 }
        let losingRMultiples = rMultiples.filter { $0 < 0 }

        return TradeInsightOutcomeMetrics(
            winRate: rate(wins(in: buckets.pricedTrades), buckets.pricedTrades.count),
            averageWinner: average(winningRMultiples),
            averageLoser: average(losingRMultiples),
            expectancy: average(rMultiples),
            profitFactor: profitFactor(for: rMultiples),
            averageHoldTime: averageHoldDuration(in: buckets.closedTrades)
        )
    }

    func setupMetrics(from riskDefinedTrades: [Trade]) -> TradeInsightSetupMetrics {
        let aPlusTrades = riskDefinedTrades.filter(\.isAPlusSetup)
        let nonAPlusTrades = riskDefinedTrades.filter { !$0.isAPlusSetup }

        return TradeInsightSetupMetrics(
            aPlusWinRate: rate(wins(in: aPlusTrades), aPlusTrades.count),
            nonAPlusWinRate: rate(wins(in: nonAPlusTrades), nonAPlusTrades.count),
            aPlusExpectancy: average(aPlusTrades.compactMap { rMultiple(for: $0) }),
            nonAPlusExpectancy: average(nonAPlusTrades.compactMap { rMultiple(for: $0) })
        )
    }

    func processMetrics(from buckets: TradeInsightTradeBuckets) -> TradeInsightProcessMetrics {
        let reviews = buckets.reviews
        let riskDefinedTrades = buckets.riskDefinedTrades

        return TradeInsightProcessMetrics(
            followedPlanRate: rate(reviews.filter(\.followedPlan).count, reviews.count),
            wouldRetakeRate: rate(reviews.filter(\.wouldRetake).count, reviews.count),
            entryQualityAverage: average(reviews.map { Double($0.entryQuality) }),
            exitQualityAverage: average(reviews.map { Double($0.exitQuality) }),
            followedPlanExpectancy: average(
                riskDefinedTrades
                    .filter { $0.review?.followedPlan == true }
                    .compactMap { rMultiple(for: $0) }
            ),
            brokePlanExpectancy: average(
                riskDefinedTrades
                    .filter { $0.review?.followedPlan == false }
                    .compactMap { rMultiple(for: $0) }
            )
        )
    }

    func riskMetrics(from buckets: TradeInsightTradeBuckets) -> TradeInsightRiskMetrics {
        let closedTrades = buckets.closedTrades
        let riskDefinedTrades = buckets.riskDefinedTrades

        return TradeInsightRiskMetrics(
            targetHitRate: rate(closedTrades.filter { $0.exitReason == .targetHit }.count, closedTrades.count),
            averagePlannedR: average(riskDefinedTrades.compactMap { plannedR(for: $0) }),
            averageMAE: average(trades.compactMap { decimalToDouble($0.mae) }),
            averageMFE: average(trades.compactMap { decimalToDouble($0.mfe) }),
            averageCostDrag: average(closedTrades.compactMap { costDrag(for: $0) }),
            highConfidenceLosers: highConfidenceLosers(in: riskDefinedTrades),
            lowConfidenceWinners: lowConfidenceWinners(in: riskDefinedTrades)
        )
    }

    func dataQualityMetrics(from buckets: TradeInsightTradeBuckets) -> TradeInsightDataQualityMetrics {
        TradeInsightDataQualityMetrics(
            reviewCoverage: rate(buckets.reviewTrades.count, buckets.totalTrades),
            stopCoverage: rate(buckets.pricedTrades.filter { $0.stopPrice != nil }.count, buckets.pricedTrades.count),
            exitReasonCoverage: rate(
                buckets.closedTrades.filter { $0.exitReason != nil }.count,
                buckets.closedTrades.count
            )
        )
    }

    func hasEntryAndExit(_ trade: Trade) -> Bool {
        trade.entryPrice != nil && trade.exitPrice != nil
    }

    func wins(in trades: [Trade]) -> Int {
        trades.filter { (priceMove(for: $0) ?? 0) > 0 }.count
    }

    func priceMove(for trade: Trade) -> Double? {
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

    func rMultiple(for trade: Trade) -> Double? {
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

    func plannedR(for trade: Trade) -> Double? {
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

    func costDrag(for trade: Trade) -> Double? {
        let commission = decimalToDouble(trade.commissions) ?? 0
        let slippage = decimalToDouble(trade.slippage) ?? 0
        let total = commission + slippage
        return total > 0 ? total : nil
    }

    func averageHoldDuration(in trades: [Trade]) -> TimeInterval? {
        let durations = trades.compactMap { trade -> TimeInterval? in
            guard let closedAt = trade.closedAt else { return nil }
            let duration = closedAt.timeIntervalSince(trade.openedAt)
            return duration >= 0 && duration.isFinite ? duration : nil
        }

        return average(durations)
    }

    func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    func profitFactor(for values: [Double]) -> Double? {
        let grossProfit = values.filter { $0 > 0 }.reduce(0, +)
        let grossLoss = abs(values.filter { $0 < 0 }.reduce(0, +))

        guard grossProfit > 0 || grossLoss > 0 else { return nil }
        guard grossLoss > 0 else { return .infinity }
        return grossProfit / grossLoss
    }

    func rate(_ part: Int, _ total: Int) -> Double? {
        guard total > 0 else { return nil }
        return Double(part) / Double(total)
    }

    func decimalToDouble(_ value: Decimal?) -> Double? {
        guard let value else { return nil }
        let result = NSDecimalNumber(decimal: value).doubleValue
        return result.isFinite ? result : nil
    }

    private func highConfidenceLosers(in trades: [Trade]) -> Int {
        trades.filter {
            $0.confidenceScore >= 4 && (rMultiple(for: $0) ?? 0) < 0
        }.count
    }

    private func lowConfidenceWinners(in trades: [Trade]) -> Int {
        trades.filter {
            $0.confidenceScore <= 2 && (rMultiple(for: $0) ?? 0) > 0
        }.count
    }
}
