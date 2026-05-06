import Foundation
import SwiftUI

enum JournalInsightsFormatting {
    static func percent(_ value: Double?) -> String {
        guard let value else { return "N/A" }
        return value.formatted(.percent.precision(.fractionLength(0)))
    }

    static func rMultiple(_ value: Double?) -> String {
        guard let value else { return "N/A" }
        return String(format: "%.2fR", value)
    }

    static func profitFactor(_ value: Double?) -> String {
        guard let value else { return "N/A" }
        guard value.isFinite else { return "Inf" }
        return String(format: "%.2f", value)
    }

    static func number(_ value: Double?) -> String {
        guard let value else { return "N/A" }
        return String(format: "%.2f", value)
    }

    static func rating(_ value: Double?) -> String {
        guard let value else { return "N/A" }
        return String(format: "%.1f / 5", value)
    }

    static func duration(_ value: TimeInterval?) -> String {
        guard let value else { return "N/A" }
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: value) ?? "N/A"
    }

    static func segmentDetail(_ segment: TradeInsights.SegmentPerformance) -> String {
        var parts = ["\(segment.trades) trades"]

        if segment.winRate != nil {
            parts.append("Win Rate \(percent(segment.winRate))")
        }

        if segment.expectancy != nil {
            parts.append("Exp \(rMultiple(segment.expectancy))")
        }

        if segment.profitFactor != nil {
            parts.append("PF \(profitFactor(segment.profitFactor))")
        }

        return parts.joined(separator: " • ")
    }

    static func valueColor(for value: Double?) -> Color? {
        guard let value else { return nil }
        return value >= 0 ? .green : .red
    }

    static func profitFactorColor(for value: Double?) -> Color? {
        guard let value else { return nil }
        guard value.isFinite else { return .green }
        return value >= 1 ? .green : .red
    }
}
