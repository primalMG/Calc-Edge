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
    @Binding var selectedTradeID: Trade.ID?
    @Binding var sortOrder: [KeyPathComparator<Trade>]
    let deleteTrade: (Trade.ID) -> Void

    var body: some View {
        Table(trades, selection: $selectedTradeID, sortOrder: $sortOrder) {
            TableColumn("Opened At") { trade in
                Text(TradeJournalFormatting.date(trade.openedAt))
            }

            TableColumn("Ticker") { trade in
                Text(TradeJournalFormatting.title(for: trade))
            }

            TableColumn("Direction") { trade in
                Text(TradeJournalFormatting.displayText(trade.direction.rawValue))
                    .foregroundStyle(trade.direction.rawValue == "long" ? Color.green : Color.red)
            }

            TableColumn("Instrument") { trade in
                Text(TradeJournalFormatting.displayText(trade.instrument.rawValue))
            }

            TableColumn("Entry Price") { trade in
                Text(TradeJournalFormatting.decimal(trade.entryPrice))
            }

            TableColumn("Exit") { trade in
                VStack(alignment: .leading, spacing: 2) {
                    Text(TradeJournalFormatting.exitStatus(for: trade))
                    HStack(spacing: 6) {
                        Text("Price: \(TradeJournalFormatting.decimal(trade.exitPrice))")
                        Text("Reason: \(TradeJournalFormatting.exitReason(for: trade))")
                    }
                    .foregroundStyle(.secondary)
                }
            }

            TableColumn("Confidence") { trade in
                Text("\(trade.confidenceScore)")
            }
        }
        .contextMenu(forSelectionType: Trade.ID.self) { items in
            if let tradeID = items.first {
                Button("Delete Trade", role: .destructive) {
                    deleteTrade(tradeID)
                }
            }
        }
    }
}
#endif
