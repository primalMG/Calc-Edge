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
    @State private var trackedSuggestionTradeID: UUID?
    @State private var persistedChangeSnapshot: TradeJournalChangeSnapshot?
    @State private var pendingChangeSnapshot: TradeJournalChangeSnapshot?
    @State private var changeLogTask: Task<Void, Never>?
    @State private var trackedChangeLogTradeID: UUID?
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
            TransactionsSection(trade: trade)

            riskStrategyReviewLayout

            if trade.instrument == .option {
                LegsSection(trade: trade)
            }

            AttachmentsSection(trade: trade)
            ChangeLogSection(trade: trade)
        }
        .navigationTitle(trade.ticker)
        .onAppear {
            configureSuggestionTracking()
            configureChangeLogTracking()
        }
        .onChange(of: currentSuggestionValues) { _, newValues in
            queueSuggestionSave(with: newValues)
        }
        .onChange(of: currentChangeSnapshot) { _, newSnapshot in
            queueChangeLog(with: newSnapshot)
        }
        .onChange(of: trade.tradeId) { _, _ in
            suggestionSaveTask?.cancel()
            configureSuggestionTracking()
            changeLogTask?.cancel()
            configureChangeLogTracking()
        }
        .onDisappear {
            flushPendingSuggestionSave()
            flushPendingChangeLog()
        }
        .toolbar {
            ToolbarItem {
                Button {
                    toggleDelete.toggle()
                } label: {
                    Image(systemName: "trash.fill")
                }
                .tint(.red)
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
        .onChange(of: unavailableOptionalSheets) { _, sheets in
            guard let activeSheet, sheets.contains(activeSheet) else {
                return
            }

            self.activeSheet = nil
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

        if trade.review != nil {
            SheetLauncherCard(
                title: "Review",
                summary: TradeJournalDetailSummary.review(for: trade)
            ) {
                activeSheet = .review
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        } else {
            ReviewSection(trade: trade)
        }
        
        if trade.context != nil {
            SheetLauncherCard(
                title: "Market Context",
                summary: TradeJournalDetailSummary.context(for: trade)
            ) {
                activeSheet = .context
            }
            .transition(.move(edge: .top).combined(with: .opacity))
        } else {
            MarketContextSection(trade: trade)
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

    #if os(iOS)
    private var unavailableOptionalSheets: Set<ActiveTradeJournalSheet> {
        var sheets: Set<ActiveTradeJournalSheet> = []

        if trade.review == nil {
            sheets.insert(.review)
        }

        if trade.context == nil {
            sheets.insert(.context)
        }

        return sheets
    }
    #endif

    private var currentSuggestionValues: [TradeSuggestionField: String] {
        TradeJournalDetailSuggestionValues.currentValues(for: trade)
    }

    private var currentChangeSnapshot: TradeJournalChangeSnapshot {
        TradeJournalChangeSnapshot(trade: trade)
    }

    private func configureSuggestionTracking() {
        let values = currentSuggestionValues
        trackedSuggestionTradeID = trade.tradeId
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
        guard trackedSuggestionTradeID == trade.tradeId,
              pendingSuggestionValues != persistedSuggestionValues else {
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

    private func configureChangeLogTracking() {
        let snapshot = currentChangeSnapshot
        trackedChangeLogTradeID = trade.tradeId
        persistedChangeSnapshot = snapshot
        pendingChangeSnapshot = snapshot
    }

    private func queueChangeLog(with snapshot: TradeJournalChangeSnapshot) {
        pendingChangeSnapshot = snapshot
        changeLogTask?.cancel()
        changeLogTask = Task {
            try? await Task.sleep(for: .seconds(2))

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                persistPendingChangeLogIfNeeded()
            }
        }
    }

    private func flushPendingChangeLog() {
        changeLogTask?.cancel()
        persistPendingChangeLogIfNeeded()
    }

    private func persistPendingChangeLogIfNeeded() {
        guard trackedChangeLogTradeID == trade.tradeId,
              let previous = persistedChangeSnapshot,
              let pending = pendingChangeSnapshot,
              pending != previous else {
            return
        }

        let details = pending.changeDetails(from: previous)
        guard !details.isEmpty else {
            persistedChangeSnapshot = pending
            return
        }

        let position = trade.positionSummary
        trade.appendValueChangeLog(
            summary: "Updated journal entry",
            detail: details.joined(separator: "\n"),
            previous: position,
            current: position
        )
        persistedChangeSnapshot = pending
        try? modelContext.save()
    }
}

#Preview {
    TradeJournalDetailView(trade: Trade(ticker: "DAL"))
}
