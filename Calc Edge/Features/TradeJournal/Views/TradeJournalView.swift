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
    @State private var selectedTrade = Set<Trade.ID>()
    @State private var sortOrder = [KeyPathComparator(\Trade.openedAt, order: .reverse)]
    @State private var newJournalIsPresent: Bool = false
    @State private var draftTrade = Trade(ticker: "")
    @State private var navigationPath = NavigationPath()

    private var sortedTrades: [Trade] {
        trades.sorted(using: sortOrder)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Table(sortedTrades, selection: $selectedTrade, sortOrder: $sortOrder) {
                TableColumn("Opened At") { trade in
                    Text(formatDate(trade.openedAt))
                }

                TableColumn("Ticker") { trade in
                    NavigationLink(trade.ticker) {
                        TradeJournalDetailView(trade: trade)
                    }
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
                Button("Open Trade Detail") {
                    if let tradeID = items.first {
                        navigationPath.append(tradeID)
                    }
                }
            } primaryAction: { items in
                if let tradeID = items.first {
                    navigationPath.append(tradeID)
                }
            }
            .navigationDestination(for: Trade.ID.self) { tradeID in
                if let trade = trades.first(where: { $0.id == tradeID }) {
                    TradeJournalDetailView(trade: trade)
                } else {
                    Text("Trade not found")
                }
            }
            .navigationTitle("Trade Journal")
            .toolbar {
                ToolbarItem {
                    Button("testing") {
                        print(trades)
                    }
                }
                ToolbarItem {
                    Button {
                        draftTrade = Trade(ticker: "")
                        newJournalIsPresent.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $newJournalIsPresent, onDismiss: {
                draftTrade = Trade(ticker: "")
            }) {
                NewJournalView(trade: draftTrade)
            }
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
