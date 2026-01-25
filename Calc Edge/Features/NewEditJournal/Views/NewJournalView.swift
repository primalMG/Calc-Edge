//
//  NewEditJournalSheet.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 20/01/2026.
//

import Foundation
import SwiftUI
import SwiftData

struct NewJournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var trade: Trade

    @State private var isNew: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                IdentificationSection(trade: trade, isNewJournalEntry: .constant(false))
                PricesSection(trade: trade)
                RiskSection(trade: trade, isNewJournalEntry: .constant(false))

                HStack {
                    Button("Save") {
                        save()
                    }
                    .tint(.green)

                    Button("Cancel") {
                        dismiss()
                    }
                    .tint(.red)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
        modelContext.insert(trade)
    }
}

#Preview {
    NewJournalView(trade: Trade(ticker: "AAPL"))
        .modelContainer(for: [Trade.self, TradeLeg.self, TradeContext.self, TradeReview.self, TradeAttachment.self], inMemory: true)
}
