import SwiftData
import SwiftUI

struct JournalImportReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var trades: [Trade]
    @State private var alert: ImportReviewAlert?

    init(trades: [Trade]) {
        _trades = State(initialValue: trades)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(trades) { trade in
                        ImportTradeEditorCard(
                            trade: trade,
                            entryNumber: entryNumber(for: trade),
                            onDelete: {
                                delete(trade)
                            }
                        )
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Review Import")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save All") {
                        saveAll()
                    }
                    .disabled(trades.isEmpty)
                }
            }
            .overlay {
                if trades.isEmpty {
                    ContentUnavailableView(
                        "No Entries",
                        systemImage: "tray",
                        description: Text("All imported entries have been removed.")
                    )
                }
            }
            .alert(item: $alert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        #if os(macOS)
        .frame(minWidth: 760, minHeight: 620)
        #endif
    }

    private func entryNumber(for trade: Trade) -> Int {
        guard let index = trades.firstIndex(where: { $0 === trade }) else {
            return 0
        }

        return index + 1
    }

    private func delete(_ trade: Trade) {
        withAnimation {
            trades.removeAll { $0 === trade }
        }
    }

    private func saveAll() {
        let invalidTickers = trades
            .map { $0.ticker.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter(\.isEmpty)

        guard invalidTickers.isEmpty else {
            alert = ImportReviewAlert(
                title: "Ticker Required",
                message: "Every imported entry needs a ticker before saving."
            )
            return
        }

        do {
            for trade in trades {
                trade.ticker = trade.ticker
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .uppercased()
                modelContext.insert(trade)
            }

            try modelContext.save()
            dismiss()
        } catch {
            alert = ImportReviewAlert(
                title: "Save Failed",
                message: error.localizedDescription
            )
        }
    }
}

private struct ImportTradeEditorCard: View {
    @Bindable var trade: Trade

    let entryNumber: Int
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Entry \(entryNumber)")
                        .font(.headline)

                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 12)

                Button(role: .destructive, action: onDelete) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Delete imported entry")
            }

            IdentificationSection(trade: trade, inEditMode: .constant(false))
            PricesSection(trade: trade)
            TransactionsSection(trade: trade)
            RiskSection(trade: trade, inEditMode: .constant(false))
        }
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var summary: String {
        let ticker = trade.ticker.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayTicker = ticker.isEmpty ? "Missing ticker" : ticker.uppercased()
        return "\(displayTicker) - \(trade.openedAt.formatted(date: .abbreviated, time: .shortened))"
    }
}

private struct ImportReviewAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

#Preview {
    JournalImportReviewView(
        trades: [
            Trade(ticker: "AAPL", shareCount: 10, entryPrice: 100),
            Trade(ticker: "MSFT", shareCount: 5, entryPrice: 250)
        ]
    )
    .modelContainer(for: [Trade.self, TradeAttachment.self, TradeContext.self, TradeLeg.self, TradeReview.self, TradeTransaction.self, TradeValueChangeLog.self], inMemory: true)
}
