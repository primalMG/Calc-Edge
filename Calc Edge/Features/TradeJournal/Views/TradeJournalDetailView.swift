import Foundation
import SwiftUI
import SwiftData

struct TradeJournalDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var toggleDelete: Bool = false
    @State private var persistenceCoordinator = TradeJournalDetailPersistenceCoordinator()
    #if os(iOS)
    @State private var activeSheet: ActiveTradeJournalSheet?
    #else
    @State private var isChangeLogExpanded = false
    #endif

    @Bindable var trade: Trade
    let deleteTrade: ((Trade.ID) -> Void)?

    init(trade: Trade, deleteTrade: ((Trade.ID) -> Void)? = nil) {
        self.trade = trade
        self.deleteTrade = deleteTrade
    }

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
            changeLogAccess
        }
        .navigationTitle(trade.ticker)
        .onAppear {
            persistenceCoordinator.configure(for: trade)
        }
        .onChange(of: currentSuggestionValues) { _, newValues in
            persistenceCoordinator.queueSuggestionSave(for: trade, values: newValues, modelContext: modelContext)
        }
        .onChange(of: currentChangeSnapshot) { _, newSnapshot in
            persistenceCoordinator.queueChangeLog(for: trade, snapshot: newSnapshot, modelContext: modelContext)
        }
        .onChange(of: trade.tradeId) { _, _ in
            persistenceCoordinator.configure(for: trade)
        }
        .onDisappear {
            persistenceCoordinator.flush(for: trade, modelContext: modelContext)
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    toggleDelete.toggle()
                } label: {
                    Image(systemName: "trash.fill")
                }
                .accessibilityLabel("Delete Journal Entry")
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
        if let deleteTrade {
            deleteTrade(trade.id)
        } else {
            modelContext.delete(trade)
            try? modelContext.saveIfNeeded()
        }
        dismiss()
    }

    @ViewBuilder
    private var changeLogAccess: some View {
        #if os(iOS)
        SheetLauncherCard(
            title: "Change Log",
            summary: changeLogSummary
        ) {
            activeSheet = .changeLog
        }
        #else
        DisclosureGroup(isExpanded: $isChangeLogExpanded) {
            ChangeLogSection(trade: trade, includesContainer: false)
                .padding(.top, 8)
        } label: {
            Text("Change Log")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation {
                        isChangeLogExpanded.toggle()
                    }
                }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        #endif
    }

    private var changeLogSummary: String {
        let count = trade.valueChangeLogs?.count ?? 0
        return count == 1 ? "1 recorded change" : "\(count) recorded changes"
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
        case .changeLog:
            ChangeLogSection(trade: trade)
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
        case .changeLog:
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
}

#Preview {
    TradeJournalDetailView(trade: Trade(ticker: "DAL"))
}
