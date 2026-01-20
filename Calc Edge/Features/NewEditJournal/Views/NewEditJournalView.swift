//
//  NewEditJournalSheet.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 20/01/2026.
//

import Foundation
import SwiftUI
import SwiftData

struct NewEditJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var trade: Trade

    @State private var isNew: Bool = false

    var body: some View {
        HStack {
            Form {
                IdentificationSection(trade: trade)
                StrategySection(trade: trade)
                PricesSection(trade: trade)
                RiskSection(trade: trade)
                ExitSection(trade: trade)
                MarketContextSection(trade: trade)
                ReviewSection(trade: trade)
                LegsSection(trade: trade)
                AttachmentsSection(trade: trade)

                HStack {
                    Button(isNew ? "Save" : "Update") {
                        save()
                    }
                    .tint(.green)

                    Button("Cancel") {
                        dismiss()
                    }
                    .tint(.red)
                }
            }
            .padding()
        }
        .onAppear {
            if trade.ticker.isEmpty {
                isNew = true
            }
        }
    }

    private func save() {
        trade.ticker = trade.ticker.uppercased()
        if isNew {
            modelContext.insert(trade)
        }
        dismiss()
    }
}

#Preview {
    NewEditJournalView(trade: Trade(ticker: "AAPL"))
        .modelContainer(for: [Trade.self, TradeLeg.self, TradeContext.self, TradeReview.self, TradeAttachment.self], inMemory: true)
}
