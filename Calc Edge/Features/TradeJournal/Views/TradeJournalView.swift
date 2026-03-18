//
//  TradeJournalView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 19/01/2026.
//

import Foundation
import SwiftUI
import SwiftData

struct TradeJournalView: View {
    @Query private var trades: [Trade]
    @State private var selectedTradeID: Trade.ID?
    @State private var sortOrder = [KeyPathComparator(\Trade.openedAt, order: .reverse)]
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openWindow) private var openWindow

    private var sortedTrades: [Trade] {
        trades.sorted(using: sortOrder)
    }
    
    var body: some View {
        Table(sortedTrades, selection: $selectedTradeID, sortOrder: $sortOrder) {
            TableColumn("Opened At") { trade in
                Text(formatDate(trade.openedAt))
            }

            TableColumn("Ticker") { trade in
                Text(trade.ticker)
            }

            TableColumn("Direction") { trade in
                Text(trade.direction.rawValue.capitalized)
            }

            TableColumn("Instrument") { trade in
                Text(trade.instrument.rawValue.capitalized)
            }

            TableColumn("Entry Price") { trade in
                VStack(alignment: .leading, spacing: 2) {
                    Text("Price: \(formatDecimal(trade.entryPrice))")
                }
            }

            TableColumn("Exit") { trade in
                VStack(alignment: .leading, spacing: 2) {
                    Text("Closed: \(trade.closedAt.map(formatDate) ?? "Open Trade")")
                    HStack(spacing: 6) {
                        Text("Price: \(formatDecimal(trade.exitPrice))")
                        Text("Reason: \(trade.exitReason?.rawValue.capitalized ?? "N/A")")
                    }
                }
            }

            TableColumn("Confidence") { trade in
                Text("\(trade.confidenceScore)")
            }
        }
        .contextMenu(forSelectionType: Trade.ID.self) { items in
            Button("Delete Trade") {
                if let tradeId = items.first {
                    delete(tradeId: tradeId)
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
        #endif
        .navigationTitle("Trade Journal")
        .toolbar {
            ToolbarItem {
                Button {
                    openWindow(id: "new-journal")
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
    }

    private var selectedTrade: Trade? {
        guard let selectedTradeID else { return nil }
        return trades.first(where: { $0.id == selectedTradeID })
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
    
    private func delete(tradeId: Trade.ID) {
        if let trade = trades.first(where: { $0.id == tradeId }) {
            if selectedTradeID == tradeId {
                selectedTradeID = nil
            }
            modelContext.delete(trade)
        }
    }

    private func formatDate(_ date: Date) -> String {
        date.formatted()
    }

    private func formatDecimal(_ value: Decimal?) -> String {
        guard let value else { return "N/A" }
        return NSDecimalNumber(decimal: value).stringValue
    }
}
