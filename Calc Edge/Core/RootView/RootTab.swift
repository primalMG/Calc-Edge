import Foundation

enum RootTab: String, Identifiable {
    case journal
    case insights
    case calculators
    case stockCalc
    case forexCalc
    case notes
    case accounts
    case suggestions
    case more

    var id: String { rawValue }

    static var availableTabs: [RootTab] {
        #if os(macOS)
        [.journal, .insights, .notes, .stockCalc, .forexCalc, .accounts, .suggestions]
        #else
        [.journal, .insights, .calculators, .notes, .more]
        #endif
    }

    var title: String {
        switch self {
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
        case .accounts:
            "Accounts"
        case .suggestions:
            "Suggestions"
        case .more:
            "More"
        }
    }

    var systemImage: String {
        switch self {
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
        case .accounts:
            "person.crop.circle"
        case .suggestions:
            "text.badge.star"
        case .more:
            "ellipsis.circle"
        }
    }
}
