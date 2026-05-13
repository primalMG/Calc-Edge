import Foundation

@MainActor
enum TradeInsightTradeMatcher {
    static func trades(
        for segment: TradeInsightSegmentPerformance,
        in trades: [Trade]
    ) -> [Trade] {
        trades
            .filter(isPricedClosedTrade)
            .filter { segmentLabel(for: $0, category: segment.category) == segment.label }
            .sorted { $0.openedAt > $1.openedAt }
    }

    static func trades(
        for item: TradeInsightCountedItem,
        kind: CountedItemKind,
        in trades: [Trade]
    ) -> [Trade] {
        trades
            .filter { trade in
                switch kind {
                case .mistake:
                    cleanLabel(trade.review?.mistakeType) == item.label
                case .exitReason:
                    trade.exitReason.map { $0.rawValue.capitalized } == item.label
                }
            }
            .sorted { $0.openedAt > $1.openedAt }
    }

    enum CountedItemKind {
        case mistake
        case exitReason
    }

    private static func isPricedClosedTrade(_ trade: Trade) -> Bool {
        trade.closedAt != nil && trade.entryPrice != nil && trade.exitPrice != nil
    }

    private static func segmentLabel(for trade: Trade, category: String) -> String {
        switch category {
        case "Strategy":
            cleanLabel(trade.strategyName)
        case "Setup":
            cleanLabel(trade.setupType)
        case "Timeframe":
            cleanLabel(trade.timeframe)
        case "Instrument":
            trade.instrument.rawValue.capitalized
        case "Direction":
            trade.direction.rawValue.capitalized
        case "Account":
            cleanLabel(trade.account)
        case "Emotion":
            trade.review?.emotionalState.rawValue.capitalized ?? "Unspecified"
        case "Market Regime":
            trade.context?.marketRegime.rawValue.capitalized ?? "Unspecified"
        case "Time of Day":
            cleanLabel(trade.context?.timeOfDayTag)
        case "Confidence":
            "Score \(trade.confidenceScore)"
        default:
            "Unspecified"
        }
    }

    private static func cleanLabel(_ label: String?) -> String {
        let trimmedLabel = label?.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedLabel?.isEmpty == false ? trimmedLabel! : "Unspecified"
    }
}
