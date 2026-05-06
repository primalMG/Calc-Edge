import Foundation

struct TradeInsights {
    enum HighlightTone {
        case positive
        case caution
        case neutral
    }

    struct Highlight: Identifiable {
        let id: String
        let title: String
        let value: String
        let detail: String
        let tone: HighlightTone
    }

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

    struct ReviewFocus {
        let title: String
        let detail: String
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

    let highlights: [Highlight]
    let nextReviewFocus: ReviewFocus?
    let bestSetup: SegmentPerformance?
    let worstSetup: SegmentPerformance?
    let edgeMapSegments: [SegmentPerformance]
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
