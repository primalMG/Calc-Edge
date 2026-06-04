import Foundation
import SwiftData

@MainActor
final class TradeJournalDetailPersistenceCoordinator {
    private var persistedSuggestionValues: [TradeSuggestionField: String] = [:]
    private var pendingSuggestionValues: [TradeSuggestionField: String] = [:]
    private var suggestionSaveTask: Task<Void, Never>?
    private var trackedSuggestionTradeID: UUID?

    private var persistedChangeSnapshot: TradeJournalChangeSnapshot?
    private var pendingChangeSnapshot: TradeJournalChangeSnapshot?
    private var changeLogTask: Task<Void, Never>?
    private var trackedChangeLogTradeID: UUID?

    func configure(for trade: Trade) {
        cancelPendingWork()
        configureSuggestionTracking(for: trade)
        configureChangeLogTracking(for: trade)
    }

    func queueSuggestionSave(
        for trade: Trade,
        values: [TradeSuggestionField: String],
        modelContext: ModelContext
    ) {
        pendingSuggestionValues = values
        suggestionSaveTask?.cancel()
        suggestionSaveTask = Task { [weak self, weak trade] in
            try? await Task.sleep(for: .seconds(2))

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                guard let self, let trade else {
                    return
                }

                self.persistPendingSuggestionValuesIfNeeded(for: trade, modelContext: modelContext)
            }
        }
    }

    func queueChangeLog(
        for trade: Trade,
        snapshot: TradeJournalChangeSnapshot,
        modelContext: ModelContext
    ) {
        pendingChangeSnapshot = snapshot
        changeLogTask?.cancel()
        changeLogTask = Task { [weak self, weak trade] in
            try? await Task.sleep(for: .seconds(2))

            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                guard let self, let trade else {
                    return
                }

                self.persistPendingChangeLogIfNeeded(for: trade, modelContext: modelContext)
            }
        }
    }

    func flush(for trade: Trade, modelContext: ModelContext) {
        suggestionSaveTask?.cancel()
        changeLogTask?.cancel()
        persistPendingSuggestionValuesIfNeeded(for: trade, modelContext: modelContext)
        persistPendingChangeLogIfNeeded(for: trade, modelContext: modelContext)
    }

    private func cancelPendingWork() {
        suggestionSaveTask?.cancel()
        changeLogTask?.cancel()
    }

    private func configureSuggestionTracking(for trade: Trade) {
        let values = TradeJournalDetailSuggestionValues.currentValues(for: trade)
        trackedSuggestionTradeID = trade.tradeId
        persistedSuggestionValues = values
        pendingSuggestionValues = values
    }

    private func persistPendingSuggestionValuesIfNeeded(for trade: Trade, modelContext: ModelContext) {
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

    private func configureChangeLogTracking(for trade: Trade) {
        let snapshot = TradeJournalChangeSnapshot(trade: trade)
        trackedChangeLogTradeID = trade.tradeId
        persistedChangeSnapshot = snapshot
        pendingChangeSnapshot = snapshot
    }

    private func persistPendingChangeLogIfNeeded(for trade: Trade, modelContext: ModelContext) {
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

        let position = trade.currentPositionSummary
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
