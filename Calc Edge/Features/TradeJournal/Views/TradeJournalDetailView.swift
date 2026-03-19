import Foundation
import SwiftUI
import SwiftData

struct TradeJournalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var toggleDelete: Bool = false
    @State private var persistedStrategyName: String = ""
    @State private var pendingStrategyName: String = ""
    @State private var pendingTradeID: UUID?
    @State private var strategySuggestionSaveTask: Task<Void, Never>?
    
    @Bindable var trade: Trade

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                IdentificationSection(trade: trade, inEditMode: .constant(true))
                
                if trade.closedAt != nil {
                    ExitSection(trade: trade)
                }
                
                PricesSection(trade: trade)
                
                RiskSection(trade: trade, inEditMode: .constant(true))
                
                
                StrategySection(trade: trade)
                
                ReviewSection(trade: trade)
                
                MarketContextSection(trade: trade)
                
                if trade.instrument == .option {
                    LegsSection(trade: trade)
                }
                
                AttachmentsSection(trade: trade)
            }
            .padding()
        }
        .navigationTitle(trade.ticker)
        .onAppear {
            configureStrategyTracking()
        }
        .onChange(of: trade.strategyName) { _, _ in
            queueStrategySuggestionSave()
        }
        .onChange(of: trade.tradeId) { _, _ in
            flushPendingStrategySuggestionSave()
            configureStrategyTracking()
        }
        .onDisappear {
            flushPendingStrategySuggestionSave()
        }
        .toolbar {
            ToolbarItem {
                Button {
                    toggleDelete.toggle()
                } label: {
                    Image(systemName: "trash.fill")
                }
                .alert("Delete Journal Entry?", isPresented: $toggleDelete) {
                    Button(role: .cancel) { } label: {
                        Text("Cancel")
                    }

                    Button(role: .destructive) {
                        delete()
                    } label: {
                        Text("Yes")
                    }

                }
            }
        }
    }
    
    private func delete() {
        modelContext.delete(trade)
        dismiss()
    }

    private var normalizedStrategyName: String {
        trade.strategyName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func configureStrategyTracking() {
        let strategyName = normalizedStrategyName

        persistedStrategyName = strategyName
        pendingStrategyName = strategyName
        pendingTradeID = trade.tradeId
    }

    private func queueStrategySuggestionSave() {
        pendingStrategyName = normalizedStrategyName
        pendingTradeID = trade.tradeId
        strategySuggestionSaveTask?.cancel()
        strategySuggestionSaveTask = Task {
            try? await Task.sleep(for: .seconds(2))

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                persistPendingStrategySuggestionIfNeeded()
            }
        }
    }

    private func flushPendingStrategySuggestionSave() {
        strategySuggestionSaveTask?.cancel()
        persistPendingStrategySuggestionIfNeeded()
    }

    private func persistPendingStrategySuggestionIfNeeded() {
        let strategyName = pendingStrategyName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !strategyName.isEmpty, strategyName != persistedStrategyName else {
            return
        }

        let uniqueKey = TradeFieldSuggestion.makeUniqueKey(
            field: StrategySuggestionField.strategyName.rawValue,
            value: strategyName
        )
        let descriptor = FetchDescriptor<TradeFieldSuggestion>(
            predicate: #Predicate { suggestion in
                suggestion.uniqueKey == uniqueKey
            }
        )

        if let existingSuggestion = try? modelContext.fetch(descriptor).first {
            existingSuggestion.value = strategyName
            existingSuggestion.useCount += 1
            existingSuggestion.lastUsedAt = .now
        } else {
            let suggestion = TradeFieldSuggestion(
                field: StrategySuggestionField.strategyName.rawValue,
                value: strategyName
            )
            modelContext.insert(suggestion)
        }

        persistedStrategyName = strategyName
        try? modelContext.save()
    }
}
