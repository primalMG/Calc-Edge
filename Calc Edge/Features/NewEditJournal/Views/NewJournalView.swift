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
    @State private var toast: ToastConfiguration?

    var body: some View {
        IdenticaftioSectionLayout {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    IdentificationSection(trade: trade, inEditMode: .constant(false))
                    PricesSection(trade: trade)
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
        .onAppear {
            if trade.ticker.isEmpty {
                isNew = true
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
            if isNew {
                modelContext.insert(trade)
                isNew = false
            }

            try modelContext.save()

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
        .modelContainer(for: [Trade.self, TradeLeg.self, TradeContext.self, TradeReview.self, TradeAttachment.self], inMemory: true)
}
