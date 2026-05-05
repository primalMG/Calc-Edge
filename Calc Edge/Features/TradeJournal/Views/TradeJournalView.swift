//
//  TradeJournalView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 19/01/2026.
//

import Foundation
import SwiftData
import SwiftUI
internal import UniformTypeIdentifiers

struct TradeJournalView: View {
    @Query private var trades: [Trade]
    @State private var selectedTradeID: Trade.ID?
    @State private var sortOrder = [KeyPathComparator(\Trade.openedAt, order: .reverse)]
    @State private var filters = TradeJournalFilters()
    @State private var showFileImporter = false
    @State private var presentedSheet: JournalPresentation?
    @State private var importAlert: ImportAlert?
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif

    @Environment(\.modelContext) private var modelContext

    private var sortedTrades: [Trade] {
        trades.sorted(using: sortOrder)
    }

    private var visibleTrades: [Trade] {
        sortedTrades.filter(filters.matches)
    }

    #if os(macOS)
    private var selectionSyncToken: [Trade.ID] {
        visibleTrades.map(\.id)
    }
    #endif

    var body: some View {
        journalContent
            .navigationTitle("Trade Journal")
            .searchable(text: $filters.tickerQuery, placement: .toolbarPrincipal)
            .toolbar {
                toolbarItems
            }
            #if os(macOS)
            .inspector(isPresented: inspectorIsPresented) {
                if let selectedTrade {
                    TradeJournalDetailView(trade: selectedTrade)
                        .inspectorColumnWidth(min: 420, ideal: 520, max: 760)
                } else {
                    ContentUnavailableView("Select a Trade", systemImage: "book")
                        .inspectorColumnWidth(min: 420, ideal: 520, max: 760)
                }
            }
            .task(id: selectionSyncToken) {
                keepSelectionInSync()
            }
            #endif
            .sheet(item: $presentedSheet) { presentation in
                switch presentation {
                case .draft(let draft):
                    NewJournalView(trade: draft.trade, isNew: true)
                case .importReview(let importReview):
                    JournalImportReviewView(trades: importReview.trades)
                }
            }
            .alert(item: $importAlert) { alert in
                Alert(
                    title: Text(alert.title),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
            }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        #if os(macOS)
        ToolbarItemGroup(placement: .principal) {
            toolbarControls
        }
        #else
        ToolbarItemGroup {
            toolbarControls
        }
        #endif
    }

    @ViewBuilder
    private var toolbarControls: some View {
        Button(action: presentNewTrade) {
            Image(systemName: "plus")
        }
        #if os(macOS)
        .keyboardShortcut("N")
        #endif
        .help("New Journal Entry")
        
        Button {
            showFileImporter = true
        } label: {
            Image(systemName: "square.and.arrow.down")
        }
        .help("Import CSV")
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let files):
                guard let file = files.first else {
                    return
                }
                importJournalCSV(from: file)
            case .failure(let error):
                importAlert = ImportAlert(
                    title: "Import Failed",
                    message: error.localizedDescription
                )
            }
        }

        Menu {
            filterMenuContent
        } label: {
            Image(systemName: filters.hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
        }
        .help("Filters Menu")
    }

    @ViewBuilder
    private var filterMenuContent: some View {
        Picker("Date", selection: $filters.date) {
            ForEach(TradeDateFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }

        Picker("Direction", selection: $filters.direction) {
            ForEach(DirectionFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }

        Picker("Instrument", selection: $filters.instrument) {
            ForEach(InstrumentFilter.allCases) { filter in
                Text(filter.title).tag(filter)
            }
        }

        if filters.hasActiveFilters {
            Divider()
            Button("Reset Filters") {
                resetFilters()
            }
        }
    }

    private var selectedTrade: Trade? {
        guard let selectedTradeID else { return nil }
        return trades.first(where: { $0.id == selectedTradeID })
    }

    @ViewBuilder
    private var journalContent: some View {
        if sortedTrades.isEmpty {
            ContentUnavailableView(
                "No Journal Entries",
                systemImage: "book.closed",
                description: Text("Add a trade to review execution, exits, and process notes.")
            )
        } else if visibleTrades.isEmpty {
            if !filters.normalizedTickerQuery.isEmpty {
                ContentUnavailableView(
                    "Ticker \(filters.normalizedTickerQuery.uppercased()) was not found",
                    systemImage: "magnifyingglass",
                    description: Text("Try another ticker or adjust the current filters.")
                )
            } else {
                ContentUnavailableView(
                    "No Matching Trades",
                    systemImage: "line.3.horizontal.decrease.circle",
                    description: Text("No trades match the selected filters.")
                )
            }
        } else {
            platformJournalContent
        }
    }

    @ViewBuilder
    private var platformJournalContent: some View {
        #if os(macOS)
        TradeJournalTable(
            trades: visibleTrades,
            selectedTradeID: $selectedTradeID,
            sortOrder: $sortOrder,
            deleteTrade: delete
        )
        #else
        TradeJournalList(
            trades: visibleTrades,
            deleteItems: deleteItems
        )
        #endif
    }

    #if os(macOS)
    private var inspectorIsPresented: Binding<Bool> {
        Binding(
            get: { selectedTradeID != nil },
            set: { isPresented in
                if !isPresented {
                    selectedTradeID = nil
                }
            }
        )
    }
    #endif

    private func presentNewTrade() {
        #if os(macOS)
        openWindow(id: "new-journal")
        #else
        presentedSheet = .draft(JournalDraftPresentation(trade: Trade(ticker: "")))
        #endif
    }

    private func importJournalCSV(from file: URL) {
        let gotAccess = file.startAccessingSecurityScopedResource()
        defer {
            if gotAccess {
                file.stopAccessingSecurityScopedResource()
            }
        }

        do {
            let trades = try JournalCSVImporter().importTrades(from: file)
            if trades.count == 1, let trade = trades.first {
                presentedSheet = .draft(JournalDraftPresentation(trade: trade))
            } else {
                presentedSheet = .importReview(JournalImportReviewPresentation(trades: trades))
            }
        } catch {
            importAlert = ImportAlert(
                title: "Import Failed",
                message: error.localizedDescription
            )
        }
    }

    private func delete(tradeId: Trade.ID) {
        guard let trade = trades.first(where: { $0.id == tradeId }) else {
            return
        }

        if selectedTradeID == tradeId {
            selectedTradeID = nil
        }

        modelContext.delete(trade)
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                delete(tradeId: visibleTrades[index].id)
            }
        }
    }

    #if os(macOS)
    private func keepSelectionInSync() {
        if let selectedTradeID,
           visibleTrades.contains(where: { $0.id == selectedTradeID }) {
            return
        }

        selectedTradeID = visibleTrades.first?.id
    }
    #endif

    private func resetFilters() {
        filters.resetSelections()
    }
}

#Preview {
    TradeJournalView()
}
