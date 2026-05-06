import Foundation

enum InsightTimeRange: String, CaseIterable, Identifiable {
    case thirtyDays
    case ninetyDays
    case yearToDate
    case all

    var id: Self { self }

    var title: String {
        switch self {
        case .thirtyDays:
            return "30D"
        case .ninetyDays:
            return "90D"
        case .yearToDate:
            return "YTD"
        case .all:
            return "All"
        }
    }

    func filter(_ trades: [Trade]) -> [Trade] {
        guard let startDate else { return trades }
        return trades.filter { $0.openedAt >= startDate }
    }

    private var startDate: Date? {
        let calendar = Calendar.current
        let now = Date.now

        switch self {
        case .thirtyDays:
            return calendar.date(byAdding: .day, value: -30, to: now)
        case .ninetyDays:
            return calendar.date(byAdding: .day, value: -90, to: now)
        case .yearToDate:
            return calendar.date(from: calendar.dateComponents([.year], from: now))
        case .all:
            return nil
        }
    }
}
