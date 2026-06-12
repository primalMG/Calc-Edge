//
//  TradeJournalTable.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 19/01/2026.
//

#if os(macOS)
import SwiftUI

struct TradeJournalTable: View {
    let trades: [Trade]
    @Binding var selectedTradeIDs: Set<Trade.ID>
    @Binding var sortOrder: [KeyPathComparator<Trade>]
    let deleteTrades: (Set<Trade.ID>) -> Void

    var body: some View {
        Table(trades, selection: $selectedTradeIDs, sortOrder: $sortOrder) {
            TableColumn("Opened At", value: \.openedAt) { trade in
                Text(TradeJournalFormatting.date(trade.openedAt))
            }

            TableColumn("Ticker", value: \.sortableTicker) { trade in
                Text(TradeJournalFormatting.title(for: trade))
            }

            TableColumn("Direction", value: \.sortableDirection) { trade in
                Text(TradeJournalFormatting.displayText(trade.direction.rawValue))
                    .foregroundStyle(trade.direction.rawValue == "long" ? Color.green : Color.red)
            }

            TableColumn("Instrument", value: \.sortableInstrument) { trade in
                Text(TradeJournalFormatting.displayText(trade.instrument.rawValue))
            }

            TableColumn("Entry Price", value: \.sortableEntryPrice) { trade in
                Text(TradeJournalFormatting.decimal(trade.entryPrice))
            }

            TableColumn("Exit", value: \.sortableExitDate) { trade in
                VStack(alignment: .leading, spacing: 2) {
                    Text(TradeJournalFormatting.exitStatus(for: trade))
                    HStack(spacing: 6) {
                        Text("Price: \(TradeJournalFormatting.decimal(trade.exitPrice))")
                        Text("Reason: \(TradeJournalFormatting.exitReason(for: trade))")
                    }
                    .foregroundStyle(.secondary)
                }
            }

            TableColumn("Confidence", value: \.confidenceScore) { trade in
                Text("\(trade.confidenceScore)")
            }
        }
        .contextMenu(forSelectionType: Trade.ID.self) { items in
            if !items.isEmpty {
                Button(items.count == 1 ? "Delete Trade" : "Delete \(items.count) Trades", role: .destructive) {
                    deleteTrades(items)
                }
            }
        }
    }
}

private extension Trade {
    var sortableTicker: String {
        ticker.uppercased()
    }

    var sortableDirection: String {
        direction.rawValue
    }

    var sortableInstrument: String {
        instrument.rawValue
    }

    var sortableEntryPrice: Double {
        guard let entryPrice else { return 0 }
        return NSDecimalNumber(decimal: entryPrice).doubleValue
    }

    var sortableExitDate: Date {
        closedAt ?? .distantFuture
    }
}
#endif
