import Foundation

enum TradeJournalDetailSummary {
    static func risk(for trade: Trade) -> String {
        let parts = [
            summaryValue(for: trade.plannedRiskAmount, prefix: "Risk"),
            summaryValue(for: trade.plannedRiskPercent, suffix: "%"),
            summaryValue(for: trade.commissions, prefix: "Fees")
        ]

        return summaryText(from: parts, fallback: "Planned risk, fees, and excursion metrics")
    }

    static func strategy(for trade: Trade) -> String {
        let parts = [
            summaryValue(for: trade.strategyName),
            summaryValue(for: trade.setupType),
            summaryValue(for: trade.timeframe),
            trade.isAPlusSetup ? "A+ setup" : nil
        ]

        return summaryText(from: parts, fallback: "Setup, thesis, catalyst, and confidence")
    }

    static func review(for trade: Trade) -> String {
        guard let review = trade.review else {
            return "No review yet"
        }

        let parts = [
            review.followedPlan ? "Followed plan" : "Plan drift",
            review.wouldRetake ? "Would retake" : "Would not retake",
            "Entry \(review.entryQuality)/5",
            "Exit \(review.exitQuality)/5"
        ]

        return summaryText(from: parts, fallback: "Execution notes and post-trade review")
    }

    static func context(for trade: Trade) -> String {
        guard let context = trade.context else {
            return "No context yet"
        }

        let parts = [
            summaryValue(for: displayText(context.marketRegime.rawValue)),
            summaryValue(for: context.vix, prefix: "VIX"),
            summaryValue(for: context.indexTrend),
            summaryValue(for: context.timeOfDayTag)
        ]

        return summaryText(from: parts, fallback: "Regime, VIX, and intraday context")
    }

    private static func summaryText(from parts: [String?], fallback: String) -> String {
        let summary = parts
            .compactMap { value in
                guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !trimmed.isEmpty else {
                    return nil
                }

                return trimmed
            }
            .joined(separator: " | ")

        return summary.isEmpty ? fallback : summary
    }

    private static func displayText(_ rawValue: String) -> String {
        let separatedWords = rawValue.replacingOccurrences(
            of: "([a-z])([A-Z])",
            with: "$1 $2",
            options: .regularExpression
        )

        return separatedWords.capitalized
    }

    private static func summaryValue(
        for value: String?,
        prefix: String? = nil,
        suffix: String? = nil
    ) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }

        return [prefix, trimmed + (suffix ?? "")]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    private static func summaryValue(
        for value: Decimal?,
        prefix: String? = nil,
        suffix: String? = nil
    ) -> String? {
        guard let value else {
            return nil
        }

        let text = NSDecimalNumber(decimal: value).stringValue + (suffix ?? "")

        return [prefix, text]
            .compactMap { $0 }
            .joined(separator: " ")
    }
}
