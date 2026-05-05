//
//  TradeJournalFormatting.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 19/01/2026.
//

import Foundation

enum TradeJournalFormatting {
    static func title(for trade: Trade) -> String {
        let ticker = trade.ticker.trimmingCharacters(in: .whitespacesAndNewlines)
        return ticker.isEmpty ? "Untitled Trade" : ticker
    }

    static func date(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    static func decimal(_ value: Decimal?) -> String {
        guard let value else { return "N/A" }
        return NSDecimalNumber(decimal: value).stringValue
    }

    static func exitStatus(for trade: Trade) -> String {
        if let closedAt = trade.closedAt {
            return "Closed \(date(closedAt))"
        }

        return "Open Trade"
    }

    static func exitReason(for trade: Trade) -> String {
        guard let exitReason = trade.exitReason else {
            return "N/A"
        }

        return displayText(exitReason.rawValue)
    }

    static func displayText(_ rawValue: String) -> String {
        let separatedWords = rawValue.replacingOccurrences(
            of: "([a-z])([A-Z])",
            with: "$1 $2",
            options: .regularExpression
        )
        return separatedWords.capitalized
    }
}
