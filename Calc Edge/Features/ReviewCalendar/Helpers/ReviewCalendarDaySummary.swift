import Foundation

enum ReviewCalendarDateMode: String, CaseIterable, Identifiable {
    case reviewDate
    case openedDate

    var id: Self { self }

    var title: String {
        switch self {
        case .reviewDate:
            return "Review Date"
        case .openedDate:
            return "Opened Date"
        }
    }
}

struct ReviewCalendarDaySummary: Identifiable {
    let date: Date
    let trades: [Trade]
    let reviewedCount: Int
    let openTradeCount: Int
    let reviewCoverage: Double?
    let topMistake: String?
    let expectancy: Double?
    let followedPlanRate: Double?

    init(date: Date, trades: [Trade]) {
        self.date = date
        self.trades = trades

        reviewedCount = trades.filter { $0.review != nil }.count
        openTradeCount = trades.filter { $0.closedAt == nil }.count
        reviewCoverage = trades.isEmpty ? nil : Double(reviewedCount) / Double(trades.count)
        topMistake = Self.topMistake(in: trades)

        if trades.isEmpty {
            expectancy = nil
            followedPlanRate = nil
        } else {
            let insights = TradeInsightsCalculator(trades: trades).calculate()
            expectancy = insights.expectancy
            followedPlanRate = insights.followedPlanRate
        }
    }

    var id: Date { date }

    var tradeCount: Int {
        trades.count
    }

    private static func topMistake(in trades: [Trade]) -> String? {
        let mistakes = trades.compactMap { trade -> String? in
            let mistake = trade.review?.mistakeType?.trimmingCharacters(in: .whitespacesAndNewlines)
            return mistake?.isEmpty == false ? mistake : nil
        }
        let grouped = Dictionary(grouping: mistakes, by: { $0 })
        return grouped.max { $0.value.count < $1.value.count }?.key
    }
}

enum ReviewCalendarSummaryBuilder {
    static func monthDays(containing date: Date, trades: [Trade], mode: ReviewCalendarDateMode) -> [ReviewCalendarDaySummary] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let visibleStart = calendar.dateInterval(of: .weekOfYear, for: monthInterval.start)?.start,
              let lastMonthDay = calendar.date(byAdding: .day, value: -1, to: monthInterval.end),
              let visibleEndWeek = calendar.dateInterval(of: .weekOfYear, for: lastMonthDay) else {
            return []
        }

        let groupedTrades = Dictionary(grouping: trades) { trade in
            calendar.startOfDay(for: calendarDate(for: trade, mode: mode))
        }

        var days: [ReviewCalendarDaySummary] = []
        var cursor = visibleStart

        while cursor < visibleEndWeek.end {
            let day = calendar.startOfDay(for: cursor)
            days.append(ReviewCalendarDaySummary(date: day, trades: groupedTrades[day] ?? []))

            guard let next = calendar.date(byAdding: .day, value: 1, to: cursor) else {
                break
            }
            cursor = next
        }

        return days
    }

    static func calendarDate(for trade: Trade, mode: ReviewCalendarDateMode) -> Date {
        switch mode {
        case .reviewDate:
            return trade.closedAt ?? trade.openedAt
        case .openedDate:
            return trade.openedAt
        }
    }
}
