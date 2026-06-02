//
//  TradeJournalIOSRow.swift
//  Calc Edge
//
//  Created by Codex on 30/05/2026.
//

#if os(iOS)
import SwiftUI

struct TradeJournalIOSRow: View {
    let trade: Trade

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            classificationChips
            accountLabel
            tradeMetrics
        }
        .padding(.vertical, 8)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(TradeJournalFormatting.title(for: trade))
                .font(.headline)

            Spacer()

            Text(TradeJournalFormatting.date(trade.openedAt))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var classificationChips: some View {
        HStack(spacing: 8) {
            TradeJournalChip(
                title: TradeJournalFormatting.displayText(trade.direction.rawValue),
                systemImage: trade.direction == .long ? "arrow.up.forward" : "arrow.down.forward",
                color: trade.direction == .long ? .green : .red
            )

            TradeJournalChip(
                title: TradeJournalFormatting.displayText(trade.instrument.rawValue),
                systemImage: trade.instrument.journalSystemImage,
                color: trade.instrument.journalColor
            )
        }
        .font(.subheadline.weight(.medium))
    }

    @ViewBuilder
    private var accountLabel: some View {
        if let account = trade.account,
           !account.isEmpty {
            Label {
                Text(account)
                    .foregroundStyle(.secondary)
            } icon: {
                Image(systemName: "person.crop.circle.fill")
                    .foregroundStyle(account.journalAccountColor)
            }
            .font(.subheadline)
        }
    }

    private var tradeMetrics: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Text("Entry \(TradeJournalFormatting.decimal(trade.entryPrice))")
                Text(TradeJournalFormatting.exitStatus(for: trade))
            }

            HStack(spacing: 12) {
                if trade.closedAt != nil && trade.exitPrice != nil {
                    Text("Exit \(TradeJournalFormatting.decimal(trade.exitPrice))")
                }

                Text("Confidence \(trade.confidenceScore)")
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

private struct TradeJournalChip: View {
    let title: String
    let systemImage: String
    let color: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }
}
#endif
