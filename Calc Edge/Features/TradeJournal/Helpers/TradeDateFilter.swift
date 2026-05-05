//
//  TradeDateFilter.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 19/01/2026.
//

import Foundation

enum TradeDateFilter: String, CaseIterable, Identifiable {
    case all
    case today
    case last7Days
    case last30Days
    case thisMonth
    case thisYear

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All Dates"
        case .today:
            return "Today"
        case .last7Days:
            return "Last 7 Days"
        case .last30Days:
            return "Last 30 Days"
        case .thisMonth:
            return "This Month"
        case .thisYear:
            return "This Year"
        }
    }

    func matches(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date.now

        switch self {
        case .all:
            return true
        case .today:
            return calendar.isDateInToday(date)
        case .last7Days:
            guard let cutoff = calendar.date(byAdding: .day, value: -7, to: now) else {
                return true
            }
            return date >= cutoff
        case .last30Days:
            guard let cutoff = calendar.date(byAdding: .day, value: -30, to: now) else {
                return true
            }
            return date >= cutoff
        case .thisMonth:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .thisYear:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        }
    }
}
