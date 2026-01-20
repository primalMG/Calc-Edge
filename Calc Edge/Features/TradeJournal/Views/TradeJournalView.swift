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

    private var sortedTrades: [Trade] {
        trades.sorted(using: sortOrder)
    }
    
    var body: some View {
        NavigationStack {
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

                TableColumn("Market / Account") { trade in
                    Text("\(trade.market ?? "N/A") / \(trade.account ?? "N/A")")
                }

                TableColumn("Entry") { trade in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Price: \(formatDecimal(trade.entryPrice))")
                        HStack(spacing: 6) {
                            Text("Stop: \(formatDecimal(trade.stopPrice))")
                            Text("Target: \(formatDecimal(trade.targetPrice))")
                        }
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

                TableColumn("Strategy") { trade in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(trade.strategyName ?? "N/A")
                        Text(trade.setupType ?? "N/A")
                            .foregroundStyle(.secondary)
                    }
                }

                TableColumn("Confidence") { trade in
                    Text("\(trade.confidenceScore)")
                }
            }
            .navigationTitle("Trade Journal")
            .toolbar {
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
                NewEditJournalView(trade: draftTrade)
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
