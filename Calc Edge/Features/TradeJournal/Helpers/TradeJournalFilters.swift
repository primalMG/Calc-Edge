//
//  TradeJournalFilters.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 19/01/2026.
//

import Foundation

struct TradeJournalFilters {
    var tickerQuery = ""
    var date: TradeDateFilter = .all
    var direction: DirectionFilter = .all
    var instrument: InstrumentFilter = .all

    var normalizedTickerQuery: String {
        tickerQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasActiveFilters: Bool {
        date != .all || direction != .all || instrument != .all
    }

    func matches(_ trade: Trade) -> Bool {
        if !normalizedTickerQuery.isEmpty &&
            !trade.ticker.localizedCaseInsensitiveContains(normalizedTickerQuery) {
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

    mutating func resetSelections() {
        date = .all
        direction = .all
        instrument = .all
    }
}
