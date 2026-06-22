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

    var rootTab: RootTab {
        startDestination.rootTab
    }

    var startDestination: AppStartDestination {
        switch self {
        case .journal:
            .journal
        case .risk:
            #if os(macOS)
            AppStartDestination(rootTab: .stockCalc)
            #else
            AppStartDestination(rootTab: .calculators, calculatorRoute: .stock)
            #endif
        case .forex:
            #if os(macOS)
            AppStartDestination(rootTab: .forexCalc)
            #else
            AppStartDestination(rootTab: .calculators, calculatorRoute: .forex)
            #endif
        case .review:
            AppStartDestination(rootTab: .reviewCalendar)
        }
    }
}
