import Foundation
import SwiftUI
import SwiftData

struct TradeJournalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var toggleDelete: Bool = false
    @State private var persistedSuggestionValues: [TradeSuggestionField: String] = [:]
    @State private var pendingSuggestionValues: [TradeSuggestionField: String] = [:]
    @State private var suggestionSaveTask: Task<Void, Never>?
    
    @Bindable var trade: Trade

    var body: some View {
        journalViewLayout {
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
        .navigationTitle(trade.ticker)
        .onAppear {
            configureSuggestionTracking()
        }
        .onChange(of: currentSuggestionValues) { _, newValues in
            queueSuggestionSave(with: newValues)
        }
        .onChange(of: trade.tradeId) { _, _ in
            flushPendingSuggestionSave()
            configureSuggestionTracking()
        }
        .onDisappear {
            flushPendingSuggestionSave()
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
    
    @ViewBuilder
    private func journalViewLayout<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        #if os(iOS)
        Form {
            content()
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
        }
        .listRowBackground(Color.clear)
        #else
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                content()
            }
            .padding()
        }
        #endif
    }
    
    private func delete() {
        modelContext.delete(trade)
        dismiss()
    }

    private var currentSuggestionValues: [TradeSuggestionField: String] {
        var values: [TradeSuggestionField: String] = [:]

        updateSuggestionValue(&values, field: .strategyName, with: trade.strategyName)
        updateSuggestionValue(&values, field: .setupType, with: trade.setupType)
        updateSuggestionValue(&values, field: .timeframe, with: trade.timeframe)
        updateSuggestionValue(&values, field: .catalyst, with: trade.catalyst)

        if let review = trade.review {
            updateSuggestionValue(&values, field: .reviewMistakeType, with: review.mistakeType)
            updateSuggestionValue(&values, field: .reviewPostTradeNotes, with: review.postTradeNotes)
            updateSuggestionValue(&values, field: .reviewWhatWentRight, with: review.whatWentRight)
            updateSuggestionValue(&values, field: .reviewWhatWentWrong, with: review.whatWentWrong)
            updateSuggestionValue(&values, field: .reviewOneImprovement, with: review.oneImprovement)
            updateSuggestionValue(&values, field: .reviewRuleCreatedOrUpdated, with: review.ruleCreatedOrUpdated)
        }

        if let context = trade.context {
            updateSuggestionValue(&values, field: .marketIndexTrend, with: context.indexTrend)
            updateSuggestionValue(&values, field: .marketSectorStrength, with: context.sectorStrength)
            updateSuggestionValue(&values, field: .marketNewsDuringTrade, with: context.newsDuringTrade)
            updateSuggestionValue(&values, field: .marketTimeOfDayTag, with: context.timeOfDayTag)
        }

        return values
    }

    private func configureSuggestionTracking() {
        let values = currentSuggestionValues
        persistedSuggestionValues = values
        pendingSuggestionValues = values
    }

    private func queueSuggestionSave(with values: [TradeSuggestionField: String]) {
        pendingSuggestionValues = values
        suggestionSaveTask?.cancel()
        suggestionSaveTask = Task {
            try? await Task.sleep(for: .seconds(2))

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                persistPendingSuggestionValuesIfNeeded()
            }
        }
    }

    private func flushPendingSuggestionSave() {
        suggestionSaveTask?.cancel()
        persistPendingSuggestionValuesIfNeeded()
    }

    private func persistPendingSuggestionValuesIfNeeded() {
        guard pendingSuggestionValues != persistedSuggestionValues else {
            return
        }

        var didPersistSuggestions = false

        for (field, value) in pendingSuggestionValues {
            if persistedSuggestionValues[field] != value {
                modelContext.upsertTradeSuggestion(field: field, value: value)
                didPersistSuggestions = true
            }
        }

        persistedSuggestionValues = pendingSuggestionValues

        if didPersistSuggestions {
            try? modelContext.save()
        }
    }

    private func updateSuggestionValue(
        _ values: inout [TradeSuggestionField: String],
        field: TradeSuggestionField,
        with value: String?
    ) {
        guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmedValue.isEmpty else {
            return
        }

        values[field] = trimmedValue
    }
}
