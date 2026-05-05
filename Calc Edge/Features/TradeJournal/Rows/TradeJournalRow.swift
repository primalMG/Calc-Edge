//
//  TradeJournalRow.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 19/01/2026.
//

import SwiftUI

struct TradeJournalRow: View {
    let trade: Trade

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(TradeJournalFormatting.title(for: trade))
                    .font(.headline)

                Spacer()

                Text(TradeJournalFormatting.date(trade.openedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Label(
                    TradeJournalFormatting.displayText(trade.direction.rawValue),
                    systemImage: trade.direction == .long ? "arrow.up.forward" : "arrow.down.forward"
                )
                .foregroundStyle(trade.direction.rawValue == "long" ? Color.green : Color.red)

                Label(
                    TradeJournalFormatting.displayText(trade.instrument.rawValue),
                    systemImage: "chart.line.uptrend.xyaxis"
                )
            }
            .font(.subheadline)

            if let account = trade.account,
               !account.isEmpty {
                Label(account, systemImage: "person.crop.circle")
            }

            HStack(spacing: 12) {
                Text("Entry \(TradeJournalFormatting.decimal(trade.entryPrice))")
                Text(TradeJournalFormatting.exitStatus(for: trade))
                Text("Confidence \(trade.confidenceScore)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if trade.closedAt != nil && trade.exitPrice != nil {
                Text("Exit \(TradeJournalFormatting.decimal(trade.exitPrice))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
