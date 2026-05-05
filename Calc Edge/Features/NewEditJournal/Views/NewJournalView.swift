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

    @State private var trade: Trade
    @State private var isNew: Bool
    @State private var toast: ToastConfiguration?

    init(trade: Trade, isNew: Bool? = nil) {
        _trade = State(initialValue: trade)
        _isNew = State(initialValue: isNew ?? trade.ticker.isEmpty)
    }

    var body: some View {
        @Bindable var trade = trade

        IdenticaftioSectionLayout {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    IdentificationSection(trade: trade, inEditMode: .constant(false))
                    PricesSection(trade: trade)
                    TransactionsSection(trade: trade)
                    RiskSection(trade: trade, inEditMode: .constant(false))
                    
#if os(macOS)
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
#endif
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .toast($toast)
    }

    private func save() {
        trade.ticker = trade.ticker
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard !trade.ticker.isEmpty else {
            toast = ToastConfiguration(
                title: "Ticker Required",
                message: "Enter a ticker before saving this journal entry.",
                state: .warning
            )
            return
        }

        do {
            let shouldClearForm = isNew

            if isNew {
                modelContext.insert(trade)
                isNew = false
            }

            try modelContext.save()

            if shouldClearForm {
                resetForm()
            }

            toast = ToastConfiguration(
                title: "Journal Saved",
                message: "Your trade journal entry has been saved.",
                state: .success
            )
        } catch {
            toast = ToastConfiguration(
                title: "Save Failed",
                message: error.localizedDescription,
                state: .error,
                duration: 4
            )
        }
    }

    private func resetForm() {
        trade = Trade(ticker: "")
        isNew = true
    }
    
    @ViewBuilder
    private func IdenticaftioSectionLayout<Cotent: View>(
        @ViewBuilder content: () -> Cotent
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            #if os(macOS)
            content()
            #elseif os(iOS)
            NavigationStack {
                content()
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancel") {
                                dismiss()
                            }
                            .tint(.red)
                        }
                        
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Save") {
                                save()
                            }
                            .tint(.green)
                        }
                    }
            }
            #endif
        }
    }
}

#Preview {
    NewJournalView(trade: Trade(ticker: "AAPL"))
        .modelContainer(for: [Trade.self, TradeAttachment.self, TradeContext.self, TradeLeg.self, TradeReview.self, TradeTransaction.self, TradeValueChangeLog.self], inMemory: true)
}
