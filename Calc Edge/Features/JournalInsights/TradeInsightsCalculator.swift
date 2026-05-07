import Foundation

struct TradeInsightsCalculator {
    let trades: [Trade]
    let minSampleSize: Int

    init(trades: [Trade], minSampleSize: Int = 3) {
        self.trades = trades
        self.minSampleSize = max(1, minSampleSize)
    }

    func calculate() -> TradeInsights {
        let buckets = tradeBuckets()
        let outcomeMetrics = outcomeMetrics(from: buckets)
        let setupMetrics = setupMetrics(from: buckets.riskDefinedTrades)
        let processMetrics = processMetrics(from: buckets)
        let riskMetrics = riskMetrics(from: buckets)
        let segmentSummary = segmentSummary(from: buckets.pricedTrades)
        let topMistakes = topMistakeItems(from: buckets.reviews)
        let exitReasons = exitReasonItems(from: buckets.closedTrades)
        let dataQuality = dataQualityMetrics(from: buckets)

        let highlights = buildHighlights(
            totalTrades: buckets.totalTrades,
            expectancy: outcomeMetrics.expectancy,
            profitFactor: outcomeMetrics.profitFactor,
            bestSetup: segmentSummary.bestSetup,
            worstSetup: segmentSummary.worstSetup,
            followedPlanExpectancy: processMetrics.followedPlanExpectancy,
            brokePlanExpectancy: processMetrics.brokePlanExpectancy,
            topMistakes: topMistakes,
            averageCostDrag: riskMetrics.averageCostDrag
        )
        let nextReviewFocus = buildNextReviewFocus(
            reviewCoverage: dataQuality.reviewCoverage,
            stopCoverage: dataQuality.stopCoverage,
            exitReasonCoverage: dataQuality.exitReasonCoverage,
            followedPlanRate: processMetrics.followedPlanRate,
            worstSetup: segmentSummary.worstSetup,
            topMistakes: topMistakes
        )

        return TradeInsights(
            totalTrades: buckets.totalTrades,
            closedTrades: buckets.closedTrades.count,
            pricedTrades: buckets.pricedTrades.count,
            riskDefinedTrades: buckets.riskDefinedTrades.count,
            winRate: outcomeMetrics.winRate,
            averageWinner: outcomeMetrics.averageWinner,
            averageLoser: outcomeMetrics.averageLoser,
            expectancy: outcomeMetrics.expectancy,
            profitFactor: outcomeMetrics.profitFactor,
            averageHoldTime: outcomeMetrics.averageHoldTime,
            aPlusWinRate: setupMetrics.aPlusWinRate,
            nonAPlusWinRate: setupMetrics.nonAPlusWinRate,
            aPlusExpectancy: setupMetrics.aPlusExpectancy,
            nonAPlusExpectancy: setupMetrics.nonAPlusExpectancy,
            followedPlanExpectancy: processMetrics.followedPlanExpectancy,
            brokePlanExpectancy: processMetrics.brokePlanExpectancy,
            followedPlanRate: processMetrics.followedPlanRate,
            wouldRetakeRate: processMetrics.wouldRetakeRate,
            entryQualityAverage: processMetrics.entryQualityAverage,
            exitQualityAverage: processMetrics.exitQualityAverage,
            targetHitRate: riskMetrics.targetHitRate,
            averagePlannedR: riskMetrics.averagePlannedR,
            averageMAE: riskMetrics.averageMAE,
            averageMFE: riskMetrics.averageMFE,
            averageCostDrag: riskMetrics.averageCostDrag,
            highConfidenceLosers: riskMetrics.highConfidenceLosers,
            lowConfidenceWinners: riskMetrics.lowConfidenceWinners,
            highlights: highlights,
            nextReviewFocus: nextReviewFocus,
            bestSetup: segmentSummary.bestSetup,
            worstSetup: segmentSummary.worstSetup,
            edgeMapSegments: segmentSummary.edgeMapSegments,
            performanceByInstrument: segmentSummary.performanceByInstrument,
            performanceByDirection: segmentSummary.performanceByDirection,
            performanceByAccount: segmentSummary.performanceByAccount,
            strengths: segmentSummary.strengths,
            weaknesses: segmentSummary.weaknesses,
            topMistakes: topMistakes,
            exitReasons: exitReasons,
            reviewCoverage: dataQuality.reviewCoverage,
            stopCoverage: dataQuality.stopCoverage,
            exitReasonCoverage: dataQuality.exitReasonCoverage
        )
    }
}

struct TradeInsightTradeBuckets {
    let totalTrades: Int
    let closedTrades: [Trade]
    let pricedTrades: [Trade]
    let riskDefinedTrades: [Trade]
    let reviewTrades: [Trade]
    let reviews: [TradeReview]
}

struct TradeInsightOutcomeMetrics {
    let winRate: Double?
    let averageWinner: Double?
    let averageLoser: Double?
    let expectancy: Double?
    let profitFactor: Double?
    let averageHoldTime: TimeInterval?
}

struct TradeInsightSetupMetrics {
    let aPlusWinRate: Double?
    let nonAPlusWinRate: Double?
    let aPlusExpectancy: Double?
    let nonAPlusExpectancy: Double?
}

struct TradeInsightProcessMetrics {
    let followedPlanRate: Double?
    let wouldRetakeRate: Double?
    let entryQualityAverage: Double?
    let exitQualityAverage: Double?
    let followedPlanExpectancy: Double?
    let brokePlanExpectancy: Double?
}

struct TradeInsightRiskMetrics {
    let targetHitRate: Double?
    let averagePlannedR: Double?
    let averageMAE: Double?
    let averageMFE: Double?
    let averageCostDrag: Double?
    let highConfidenceLosers: Int
    let lowConfidenceWinners: Int
}

struct TradeInsightSegmentSummary {
    let bestSetup: TradeInsightSegmentPerformance?
    let worstSetup: TradeInsightSegmentPerformance?
    let edgeMapSegments: [TradeInsightSegmentPerformance]
    let performanceByInstrument: [TradeInsightSegmentPerformance]
    let performanceByDirection: [TradeInsightSegmentPerformance]
    let performanceByAccount: [TradeInsightSegmentPerformance]
    let strengths: [TradeInsightSegmentPerformance]
    let weaknesses: [TradeInsightSegmentPerformance]
}

struct TradeInsightDataQualityMetrics {
    let reviewCoverage: Double?
    let stopCoverage: Double?
    let exitReasonCoverage: Double?
}
