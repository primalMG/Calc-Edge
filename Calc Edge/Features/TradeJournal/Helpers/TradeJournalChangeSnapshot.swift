import Foundation

struct TradeJournalChangeSnapshot: Equatable {
    private static let orderedFields = [
        "Ticker",
        "Market",
        "Account",
        "Instrument",
        "Direction",
        "Opened",
        "Closed",
        "Strategy",
        "Setup",
        "Timeframe",
        "Thesis",
        "Catalyst",
        "Confidence",
        "A+ Setup",
        "Planned Shares",
        "Entry Price",
        "Exit Price",
        "Exchange Rate",
        "Stop Price",
        "Target Price",
        "Planned Risk",
        "Planned Risk %",
        "Commissions",
        "Slippage",
        "MAE",
        "MFE",
        "Exit Reason",
        "Market Regime",
        "VIX",
        "Index Trend",
        "Sector Strength",
        "News During Trade",
        "Time of Day",
        "Followed Plan",
        "Entry Quality",
        "Exit Quality",
        "Emotional State",
        "Mistake Type",
        "Would Retake",
        "Post Trade Notes",
        "What Went Right",
        "What Went Wrong",
        "One Improvement",
        "Rule Created/Updated",
        "Legs",
        "Attachments"
    ]

    private let values: [String: String]

    init(trade: Trade) {
        values = [
            "Ticker": trade.ticker,
            "Market": Self.text(trade.market),
            "Account": Self.text(trade.account),
            "Instrument": trade.instrument.rawValue,
            "Direction": trade.direction.rawValue,
            "Opened": Self.date(trade.openedAt),
            "Closed": Self.date(trade.closedAt),
            "Strategy": Self.text(trade.strategyName),
            "Setup": Self.text(trade.setupType),
            "Timeframe": Self.text(trade.timeframe),
            "Thesis": Self.text(trade.thesis),
            "Catalyst": Self.text(trade.catalyst),
            "Confidence": String(trade.confidenceScore),
            "A+ Setup": trade.isAPlusSetup ? "Yes" : "No",
            "Planned Shares": Self.decimal(trade.shareCount),
            "Entry Price": Self.decimal(trade.entryPrice),
            "Exit Price": Self.decimal(trade.exitPrice),
            "Exchange Rate": Self.decimal(trade.exchangeRate),
            "Stop Price": Self.decimal(trade.stopPrice),
            "Target Price": Self.decimal(trade.targetPrice),
            "Planned Risk": Self.decimal(trade.plannedRiskAmount),
            "Planned Risk %": Self.decimal(trade.plannedRiskPercent),
            "Commissions": Self.decimal(trade.commissions),
            "Slippage": Self.decimal(trade.slippage),
            "MAE": Self.decimal(trade.mae),
            "MFE": Self.decimal(trade.mfe),
            "Exit Reason": trade.exitReason?.rawValue ?? Self.emptyValue,
            "Market Regime": trade.context?.marketRegime.rawValue ?? Self.emptyValue,
            "VIX": Self.decimal(trade.context?.vix),
            "Index Trend": Self.text(trade.context?.indexTrend),
            "Sector Strength": Self.text(trade.context?.sectorStrength),
            "News During Trade": Self.text(trade.context?.newsDuringTrade),
            "Time of Day": Self.text(trade.context?.timeOfDayTag),
            "Followed Plan": trade.review.map { $0.followedPlan ? "Yes" : "No" } ?? Self.emptyValue,
            "Entry Quality": trade.review.map { String($0.entryQuality) } ?? Self.emptyValue,
            "Exit Quality": trade.review.map { String($0.exitQuality) } ?? Self.emptyValue,
            "Emotional State": trade.review?.emotionalState.rawValue ?? Self.emptyValue,
            "Mistake Type": Self.text(trade.review?.mistakeType),
            "Would Retake": trade.review.map { $0.wouldRetake ? "Yes" : "No" } ?? Self.emptyValue,
            "Post Trade Notes": Self.text(trade.review?.postTradeNotes),
            "What Went Right": Self.text(trade.review?.whatWentRight),
            "What Went Wrong": Self.text(trade.review?.whatWentWrong),
            "One Improvement": Self.text(trade.review?.oneImprovement),
            "Rule Created/Updated": Self.text(trade.review?.ruleCreatedOrUpdated),
            "Legs": String(trade.legs?.count ?? 0),
            "Attachments": String(trade.attachments?.count ?? 0)
        ]
    }

    func changeDetails(from previous: TradeJournalChangeSnapshot) -> [String] {
        Self.orderedFields.compactMap { field in
            let oldValue = previous.values[field] ?? Self.emptyValue
            let newValue = values[field] ?? Self.emptyValue

            guard oldValue != newValue else {
                return nil
            }

            return "\(field): \(oldValue) -> \(newValue)"
        }
    }

    private static let emptyValue = "None"

    private static func text(_ value: String?) -> String {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return Self.emptyValue
        }

        return trimmed
    }

    private static func decimal(_ value: Decimal?) -> String {
        guard let value else {
            return Self.emptyValue
        }

        return ValueDisplayFormatter.decimal(value)
    }

    private static func decimal(_ value: Decimal) -> String {
        ValueDisplayFormatter.decimal(value)
    }

    private static func date(_ value: Date?) -> String {
        guard let value else {
            return Self.emptyValue
        }

        return Self.date(value)
    }

    private static func date(_ value: Date) -> String {
        value.formatted(date: .abbreviated, time: .shortened)
    }
}
