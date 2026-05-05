import Foundation

enum ActiveTradeJournalSheet: String, Identifiable {
    case risk
    case strategy
    case review
    case context
    case changeLog

    var id: String { rawValue }

    var title: String {
        switch self {
        case .risk:
            return "Risk"
        case .strategy:
            return "Strategy"
        case .review:
            return "Review"
        case .context:
            return "Context"
        case .changeLog:
            return "Change Log"
        }
    }
}
