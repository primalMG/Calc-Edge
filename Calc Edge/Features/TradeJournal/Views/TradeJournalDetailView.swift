import Foundation
import SwiftUI
import SwiftData

private enum ActiveTradeJournalSheet: String, Identifiable {
    case risk
    case strategy
    case review
    case context

    var id: String { rawValue }

    var title: String {
        switch self {
        case .risk:
            return "Risk"
        case .strategy:
            return "Strategy"
        case .review:
            return "Review"
        case .context:
            return "Context"
        }
    }
}

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
            summary: riskSummary
        ) {
            activeSheet = .risk
        }

        SheetLauncherCard(
            title: "Strategy",
            summary: strategySummary
        ) {
            activeSheet = .strategy
        }

        SheetLauncherCard(
            title: "Review",
            summary: reviewSummary
        ) {
            activeSheet = .review
        }
        
        SheetLauncherCard(
            title: "Market Context",
            summary: contextSummary
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
            return [.fraction(0.45)]
        case .strategy:
            return [.fraction(0.47)]
        case .review:
            return [.large]
        }
    }

    private var riskSummary: String {
        let parts = [
            summaryValue(for: trade.plannedRiskAmount, prefix: "Risk"),
            summaryValue(for: trade.plannedRiskPercent, suffix: "%"),
            summaryValue(for: trade.commissions, prefix: "Fees")
        ]
        return summaryText(from: parts, fallback: "Planned risk, fees, and excursion metrics")
    }

    private var strategySummary: String {
        let parts = [
            summaryValue(for: trade.strategyName),
            summaryValue(for: trade.setupType),
            summaryValue(for: trade.timeframe),
            trade.isAPlusSetup ? "A+ setup" : nil
        ]
        return summaryText(from: parts, fallback: "Setup, thesis, catalyst, and confidence")
    }

    private var reviewSummary: String {
        guard let review = trade.review else {
            return "No review yet"
        }

        let parts = [
            review.followedPlan ? "Followed plan" : "Plan drift",
            review.wouldRetake ? "Would retake" : "Would not retake",
            "Entry \(review.entryQuality)/5",
            "Exit \(review.exitQuality)/5"
        ]
        return summaryText(from: parts, fallback: "Execution notes and post-trade review")
    }
    
    private var contextSummary: String {
        guard let context = trade.context else {
            return "No context yet"
        }

        let parts = [
            summaryValue(for: displayText(context.marketRegime.rawValue)),
            summaryValue(for: context.vix, prefix: "VIX"),
            summaryValue(for: context.indexTrend),
            summaryValue(for: context.timeOfDayTag)
        ]

        return summaryText(from: parts, fallback: "Regime, VIX, and intraday context")
    }

    private func summaryText(from parts: [String?], fallback: String) -> String {
        let summary = parts
            .compactMap { value in
                guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !trimmed.isEmpty else {
                    return nil
                }

                return trimmed
            }
            .joined(separator: " | ")

        return summary.isEmpty ? fallback : summary
    }

    private func displayText(_ rawValue: String) -> String {
        let separatedWords = rawValue.replacingOccurrences(
            of: "([a-z])([A-Z])",
            with: "$1 $2",
            options: .regularExpression
        )
        return separatedWords.capitalized
    }

    private func summaryValue(
        for value: String?,
        prefix: String? = nil,
        suffix: String? = nil
    ) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }

        return [prefix, trimmed + (suffix ?? "")]
            .compactMap { $0 }
            .joined(separator: " ")
    }

    private func summaryValue(
        for value: Decimal?,
        prefix: String? = nil,
        suffix: String? = nil
    ) -> String? {
        guard let value else {
            return nil
        }

        let text = NSDecimalNumber(decimal: value).stringValue + (suffix ?? "")
        return [prefix, text]
            .compactMap { $0 }
            .joined(separator: " ")
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

private struct SheetLauncherCard: View {
    let title: String
    let summary: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)

                    Text(summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 12)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    TradeJournalDetailView(trade: Trade(ticker: "DAL"))
}
