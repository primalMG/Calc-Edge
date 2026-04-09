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
    #if os(iOS)
    @State private var activeSheet: ActiveTradeJournalSheet?
    #endif

    @Bindable var trade: Trade

    var body: some View {
        journalViewLayout {
            IdentificationSection(trade: trade, inEditMode: .constant(true))

            if trade.closedAt != nil {
                ExitSection(trade: trade)
            }

            PricesSection(trade: trade)

            riskStrategyReviewLayout

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
        #if os(iOS)
        .sheet(item: $activeSheet) { sheet in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        sheetContent(for: sheet)
                    }
                    .padding()
                }
                .navigationTitle(sheet.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") {
                            activeSheet = nil
                        }
                    }
                }
            }
            .presentationDetents(detents(for: sheet))
        }
        #endif
    }

    @ViewBuilder
    private func journalViewLayout<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        #if os(iOS)
        Form {
            content()
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
        }
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

    @ViewBuilder
    private var riskStrategyReviewLayout: some View {
        #if os(iOS)
        SheetLauncherCard(
            title: "Risk",
            summary: TradeJournalDetailSummary.risk(for: trade)
        ) {
            activeSheet = .risk
        }

        SheetLauncherCard(
            title: "Strategy",
            summary: TradeJournalDetailSummary.strategy(for: trade)
        ) {
            activeSheet = .strategy
        }

        SheetLauncherCard(
            title: "Review",
            summary: TradeJournalDetailSummary.review(for: trade)
        ) {
            activeSheet = .review
        }
        
        SheetLauncherCard(
            title: "Market Context",
            summary: TradeJournalDetailSummary.context(for: trade)
        ) {
            activeSheet = .context
        }
        #else
        RiskSection(trade: trade, inEditMode: .constant(true))
        StrategySection(trade: trade)
        ReviewSection(trade: trade)
        MarketContextSection(trade: trade)
        #endif
    }

    @ViewBuilder
    private func sheetContent(for sheet: ActiveTradeJournalSheet) -> some View {
        switch sheet {
        case .risk:
            RiskSection(trade: trade, inEditMode: .constant(true))
        case .strategy:
            StrategySection(trade: trade)
        case .review:
            ReviewSection(trade: trade)
        case .context:
            MarketContextSection(trade: trade)
        }
    }

    private func detents(for sheet: ActiveTradeJournalSheet) -> Set<PresentationDetent> {
        switch sheet {
        case .risk:
            return [.fraction(0.35)]
        case .context:
            return [.fraction(0.4)]
        case .strategy:
            return [.fraction(0.47)]
        case .review:
            return [.large]
        }
    }

    private var currentSuggestionValues: [TradeSuggestionField: String] {
        TradeJournalDetailSuggestionValues.currentValues(for: trade)
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
}

#Preview {
    TradeJournalDetailView(trade: Trade(ticker: "DAL"))
}
