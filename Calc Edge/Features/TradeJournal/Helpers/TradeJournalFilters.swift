//
//  TradeJournalFilters.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 19/01/2026.
//

import Foundation

struct TradeJournalFilters {
    var searchQuery = ""
    var date: TradeDateFilter = .all
    var direction: DirectionFilter = .all
    var instrument: InstrumentFilter = .all

    var normalizedSearchQuery: String {
        searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasActiveFilters: Bool {
        date != .all || direction != .all || instrument != .all
    }

    func matches(_ trade: Trade) -> Bool {
        if !normalizedSearchQuery.isEmpty && !matchesSearchQuery(trade) {
            return false
        }

        guard date.matches(trade.openedAt) else {
            return false
        }

        guard direction.matches(trade.direction) else {
            return false
        }

        return instrument.matches(trade.instrument)
    }

    private func matchesSearchQuery(_ trade: Trade) -> Bool {
        trade.ticker.localizedCaseInsensitiveContains(normalizedSearchQuery) ||
            trade.instrument.rawValue.localizedCaseInsensitiveContains(normalizedSearchQuery) ||
            trade.direction.rawValue.localizedCaseInsensitiveContains(normalizedSearchQuery)
    }

    mutating func resetSelections() {
        date = .all
        direction = .all
        instrument = .all
    }
}
