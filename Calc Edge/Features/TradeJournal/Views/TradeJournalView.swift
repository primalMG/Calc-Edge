//
//  TradeJournalView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 19/01/2026.
//

import Foundation
import SwiftData
import SwiftUI

struct TradeJournalView: View {
    @Query private var trades: [Trade]
    @State private var selectedTradeID: Trade.ID?
    @State private var sortOrder = [KeyPathComparator(\Trade.openedAt, order: .reverse)]
    #if os(iOS)
    @State private var presentSheet = false
    #elseif os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif

    @Environment(\.modelContext) private var modelContext

    private var sortedTrades: [Trade] {
        trades.sorted(using: sortOrder)
    }

    var body: some View {
        journalContent
            .navigationTitle("Trade Journal")
            .toolbar {
                ToolbarItem {
                    Button(action: presentNewTrade) {
                        Image(systemName: "plus")
                    }
                }
            }
            #if os(macOS)
            .inspector(isPresented: inspectorIsPresented) {
                if let selectedTrade {
                    TradeJournalDetailView(trade: selectedTrade)
                        .inspectorColumnWidth(min: 420, ideal: 520, max: 760)
                } else {
                    ContentUnavailableView("Select a Trade", systemImage: "book")
                        .inspectorColumnWidth(min: 420, ideal: 520, max: 760)
                }
            }
            .onAppear(perform: syncInitialSelection)
            .onChange(of: trades.count) { _, _ in
                keepSelectionInSync()
            }
            #endif
            #if os(iOS)
            .sheet(isPresented: $presentSheet) {
                NewJournalView(trade: Trade(ticker: ""))
            }
            #endif
    }

    private var selectedTrade: Trade? {
        guard let selectedTradeID else { return nil }
        return trades.first(where: { $0.id == selectedTradeID })
    }

    @ViewBuilder
    private var journalContent: some View {
        if sortedTrades.isEmpty {
            ContentUnavailableView(
                "No Journal Entries",
                systemImage: "book.closed",
                description: Text("Add a trade to review execution, exits, and process notes.")
            )
        } else {
            platformJournalContent
        }
    }

    @ViewBuilder
    private var platformJournalContent: some View {
        #if os(macOS)
        TradeJournalTable(
            trades: sortedTrades,
            selectedTradeID: $selectedTradeID,
            sortOrder: $sortOrder,
            deleteTrade: delete
        )
        #else
        TradeJournalList(
            trades: sortedTrades,
            deleteItems: deleteItems
        )
        #endif
    }

    #if os(macOS)
    private var inspectorIsPresented: Binding<Bool> {
        Binding(
            get: { selectedTradeID != nil },
            set: { isPresented in
                if !isPresented {
                    selectedTradeID = nil
                }
            }
        )
    }
    #endif

    private func presentNewTrade() {
        #if os(macOS)
        openWindow(id: "new-journal")
        #else
        presentSheet = true
        #endif
    }

    private func delete(tradeId: Trade.ID) {
        guard let trade = trades.first(where: { $0.id == tradeId }) else {
            return
        }

        if selectedTradeID == tradeId {
            selectedTradeID = nil
        }

        modelContext.delete(trade)
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                delete(tradeId: sortedTrades[index].id)
            }
        }
    }

    #if os(macOS)
    private func syncInitialSelection() {
        if selectedTradeID == nil {
            selectedTradeID = sortedTrades.first?.id
        }
    }

    private func keepSelectionInSync() {
        if let selectedTradeID,
           sortedTrades.contains(where: { $0.id == selectedTradeID }) {
            return
        }

        selectedTradeID = sortedTrades.first?.id
    }
    #endif
}

#if os(macOS)
private struct TradeJournalTable: View {
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

#if os(iOS)
private struct TradeJournalList: View {
    let trades: [Trade]
    let deleteItems: (IndexSet) -> Void
    @State private var searchTxt: String = ""

    var body: some View {
        List {
            ForEach(trades) { trade in
                NavigationLink {
                    TradeJournalDetailView(trade: trade)
                } label: {
                    TradeJournalRow(trade: trade)
                }
            }
            .onDelete(perform: deleteItems)
        }
        .searchable(text: $searchTxt)
    }
}
#endif

private struct TradeJournalRow: View {
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
                Label(
                    TradeJournalFormatting.displayText(trade.instrument.rawValue),
                    systemImage: "chart.line.uptrend.xyaxis"
                )

                if let account = trade.account,
                   !account.isEmpty {
                    Label(account, systemImage: "person.crop.circle")
                }
            }
            .font(.subheadline)

            HStack(spacing: 12) {
                Text("Entry \(TradeJournalFormatting.decimal(trade.entryPrice))")
                Text(TradeJournalFormatting.exitStatus(for: trade))
                Text("Confidence \(trade.confidenceScore)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

private enum TradeJournalFormatting {
    static func title(for trade: Trade) -> String {
        let ticker = trade.ticker.trimmingCharacters(in: .whitespacesAndNewlines)
        return ticker.isEmpty ? "Untitled Trade" : ticker
    }

    static func date(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    static func decimal(_ value: Decimal?) -> String {
        guard let value else { return "N/A" }
        return NSDecimalNumber(decimal: value).stringValue
    }

    static func exitStatus(for trade: Trade) -> String {
        if let closedAt = trade.closedAt {
            return "Closed \(date(closedAt))"
        }

        return "Open Trade"
    }

    static func exitReason(for trade: Trade) -> String {
        guard let exitReason = trade.exitReason else {
            return "N/A"
        }

        return displayText(exitReason.rawValue)
    }

    static func displayText(_ rawValue: String) -> String {
        let separatedWords = rawValue.replacingOccurrences(
            of: "([a-z])([A-Z])",
            with: "$1 $2",
            options: .regularExpression
        )
        return separatedWords.capitalized
    }
}

#Preview {
    TradeJournalView()
}
