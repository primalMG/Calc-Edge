import Foundation

enum RootTab: String, Identifiable {
    case dashboard
    case journal
    case insights
    case calculators
    case stockCalc
    case forexCalc
    case notes
    case suggestions

    var id: String { rawValue }

    static var availableTabs: [RootTab] {
        #if os(macOS)
        [.dashboard, .journal, .insights, .notes, .stockCalc, .forexCalc, .suggestions]
        #else
        [.journal, .insights, .calculators, .notes, .suggestions]
        #endif
    }

    var title: String {
        switch self {
        case .dashboard:
            "Dashboard"
        case .journal:
            "Journal"
        case .insights:
            "Insights"
        case .calculators:
            "Calculators"
        case .stockCalc:
            "Stock Calc"
        case .forexCalc:
            "Forex Calc"
        case .notes:
            "Notes"
        case .suggestions:
            "Suggestions"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            "house"
        case .journal:
            "book"
        case .insights:
            "sparkles"
        case .calculators:
            "plus.forwardslash.minus"
        case .stockCalc:
            "chart.line.uptrend.xyaxis"
        case .forexCalc:
            "dollarsign.circle"
        case .notes:
            "note.text"
        case .suggestions:
            "text.badge.star"
        }
    }
}
