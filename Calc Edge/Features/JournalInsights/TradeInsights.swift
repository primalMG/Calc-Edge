import Foundation

enum TradeInsightHighlightTone {
    case positive
    case caution
    case neutral
}

struct TradeInsightHighlight: Identifiable {
    let id: String
    let title: String
    let value: String
    let detail: String
    let tone: TradeInsightHighlightTone
}

struct TradeInsightSegmentPerformance: Identifiable {
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

struct TradeInsightCountedItem: Identifiable {
    let id: String
    let label: String
    let count: Int
    let percentage: Double?
}

struct TradeInsightReviewFocus {
    let title: String
    let detail: String
}

struct TradeInsights {
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
    let aPlusExpectancy: Double?
    let nonAPlusExpectancy: Double?
    let followedPlanExpectancy: Double?
    let brokePlanExpectancy: Double?

    let followedPlanRate: Double?
    let wouldRetakeRate: Double?
    let entryQualityAverage: Double?
    let exitQualityAverage: Double?
    let targetHitRate: Double?
    let averagePlannedR: Double?
    let averageMAE: Double?
    let averageMFE: Double?
    let averageCostDrag: Double?
    let highConfidenceLosers: Int
    let lowConfidenceWinners: Int

    let highlights: [TradeInsightHighlight]
    let nextReviewFocus: TradeInsightReviewFocus?
    let bestSetup: TradeInsightSegmentPerformance?
    let worstSetup: TradeInsightSegmentPerformance?
    let edgeMapSegments: [TradeInsightSegmentPerformance]
    let performanceByInstrument: [TradeInsightSegmentPerformance]
    let performanceByDirection: [TradeInsightSegmentPerformance]
    let performanceByAccount: [TradeInsightSegmentPerformance]
    let strengths: [TradeInsightSegmentPerformance]
    let weaknesses: [TradeInsightSegmentPerformance]
    let topMistakes: [TradeInsightCountedItem]
    let exitReasons: [TradeInsightCountedItem]

    let reviewCoverage: Double?
    let stopCoverage: Double?
    let exitReasonCoverage: Double?
}
