import Foundation

enum ReviewCalendarSelectionResolver {
    static func selectedDay(
        from days: [ReviewCalendarDaySummary],
        visibleMonth: Date,
        calendar: Calendar,
        preferredSelection: Date?,
        previousSelection: Date?
    ) -> ReviewCalendarDaySummary? {
        if let preferredSelection,
           let preferredDay = days.first(where: { calendar.isDate($0.date, inSameDayAs: preferredSelection) }) {
            return preferredDay
        }

        if let previousSelection,
           calendar.isDate(previousSelection, equalTo: visibleMonth, toGranularity: .month),
           let previousDay = days.first(where: { calendar.isDate($0.date, inSameDayAs: previousSelection) }) {
            return previousDay
        }

        if calendar.isDate(visibleMonth, equalTo: Date.now, toGranularity: .month),
           let today = days.first(where: { calendar.isDate($0.date, inSameDayAs: Date.now) }) {
            return today
        }

        return days.first(where: { !$0.trades.isEmpty })
    }
}
