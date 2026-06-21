import Foundation

enum OnboardingGoal: String, CaseIterable, Identifiable {
    case journal
    case risk
    case forex
    case review

    var id: String { rawValue }

    var title: String {
        switch self {
        case .journal:
            "Journal Trades"
        case .risk:
            "Calculate Risk"
        case .forex:
            "Track Forex"
        case .review:
            "Review Performance"
        }
    }

    var detail: String {
        switch self {
        case .journal:
            "Log entries, exits, process notes, and attachments."
        case .risk:
            "Size stock positions from account risk and trade levels."
        case .forex:
            "Save currency calculations and reference exchange rates."
        case .review:
            "Build habits around calendar reviews and journal insights."
        }
    }

    var systemImage: String {
        switch self {
        case .journal:
            "book"
        case .risk:
            "chart.line.uptrend.xyaxis"
        case .forex:
            "dollarsign.circle"
        case .review:
            "calendar"
        }
    }

    var nextStep: String {
        switch self {
        case .journal:
            "create or import a journal entry"
        case .risk:
            "open the stock risk calculator"
        case .forex:
            "create a forex calculation"
        case .review:
            "open the review calendar"
        }
    }

    var rootTab: RootTab {
        switch self {
        case .journal:
            .journal
        case .risk:
            #if os(macOS)
            .stockCalc
            #else
            .calculators
            #endif
        case .forex:
            #if os(macOS)
            .forexCalc
            #else
            .calculators
            #endif
        case .review:
            .reviewCalendar
        }
    }
}
