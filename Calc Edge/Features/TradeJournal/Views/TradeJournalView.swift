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
    @State private var fetchLimit = PlatformPageSize.initial

    var body: some View {
        TradeJournalPagedView(fetchLimit: fetchLimit) {
            fetchLimit += PlatformPageSize.increment
        }
    }
}

private struct TradeJournalPagedView: View {
    @Query private var trades: [Trade]
    @State private var selectedTradeIDs = Set<Trade.ID>()
    @State private var pendingDeletedTradeIDs = Set<Trade.ID>()
    @State private var sortOrder = [KeyPathComparator(\Trade.openedAt, order: .reverse)]
    @State private var filters = TradeJournalFilters()
    @State private var showFileImporter = false
    @State private var presentedSheet: JournalPresentation?
    @State private var importAlert: ImportAlert?
    @State private var isImportingCSV = false
    #if os(macOS)
    @Environment(\.openWindow) private var openWindow
    #endif

    @Environment(\.modelContext) private var modelContext

    let fetchLimit: Int
    let loadMore: () -> Void

    init(fetchLimit: Int, loadMore: @escaping () -> Void) {
        self.fetchLimit = fetchLimit
        self.loadMore = loadMore

        var descriptor = FetchDescriptor<Trade>(
            sortBy: [SortDescriptor(\.openedAt, order: .reverse)]
        )
        descriptor.fetchLimit = fetchLimit
        _trades = Query(descriptor)
    }

    private var activeTrades: [Trade] {
        trades.filter { !pendingDeletedTradeIDs.contains($0.id) }
    }

    private var sortedTrades: [Trade] {
        activeTrades.sorted(using: sortOrder)
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
            .searchable(
                text: $filters.searchQuery,
                placement: .toolbarPrincipal,
                prompt: "Search ticker, instrument, or direction"
            )
            .toolbar {
                toolbarItems
            }
            .overlay {
                if isImportingCSV {
                    ProgressView("Importing CSV...")
                        .padding(18)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            #if os(macOS)
            .task(id: selectionSyncToken) {
                keepSelectionInSync()
            }
            #endif
            .onChange(of: trades.map(\.id)) { _, tradeIDs in
                pendingDeletedTradeIDs.formIntersection(Set(tradeIDs))
            }
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
        .accessibilityLabel("New Journal Entry")
        .help("New Journal Entry")
        
        Button {
            showFileImporter = true
        } label: {
            Image(systemName: "square.and.arrow.down")
        }
        .disabled(isImportingCSV)
        .accessibilityLabel("Import CSV")
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
        .accessibilityLabel("Filters")
        .accessibilityValue(filters.hasActiveFilters ? "Active filters" : "No active filters")
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
        visibleTrades.first(where: { selectedTradeIDs.contains($0.id) })
    }

    private var canLoadMore: Bool {
        trades.count >= fetchLimit
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
            if !filters.normalizedSearchQuery.isEmpty {
                ContentUnavailableView(
                    "No results for \(filters.normalizedSearchQuery)",
                    systemImage: "magnifyingglass",
                    description: Text("Try another ticker, instrument, or direction, or adjust the current filters.")
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
        HSplitView {
            VStack(spacing: 0) {
                TradeJournalTable(
                    trades: visibleTrades,
                    selectedTradeIDs: $selectedTradeIDs,
                    sortOrder: $sortOrder,
                    deleteTrades: delete
                )

                PagedLoadMoreFooter(
                    visibleCount: visibleTrades.count,
                    canLoadMore: canLoadMore,
                    loadMore: loadMore
                )
                .padding(.horizontal)
            }
            .frame(minWidth: 720)

            tradeDetail
                .frame(minWidth: 320, idealWidth: 420, maxWidth: 960)
        }
        #else
        TradeJournalList(
            trades: visibleTrades,
            deleteItems: deleteItems,
            canLoadMore: canLoadMore,
            loadMore: loadMore
        )
        #endif
    }

    #if os(macOS)
    @ViewBuilder
    private var tradeDetail: some View {
        ZStack {
            if let selectedTrade {
                TradeJournalDetailView(trade: selectedTrade) { tradeID in
                    deleteFromDetail(tradeId: tradeID)
                }
            } else {
                ContentUnavailableView("Select a Trade", systemImage: "book")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        guard !isImportingCSV else {
            return
        }

        isImportingCSV = true

        Task {
            try? await Task.sleep(nanoseconds: 150_000_000)

            let gotAccess = file.startAccessingSecurityScopedResource()
            defer {
                if gotAccess {
                    file.stopAccessingSecurityScopedResource()
                }

                isImportingCSV = false
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
    }

    private func delete(tradeId: Trade.ID) {
        guard let trade = activeTrades.first(where: { $0.id == tradeId }) else {
            return
        }

        selectedTradeIDs.remove(tradeId)
        pendingDeletedTradeIDs.insert(tradeId)

        modelContext.delete(trade)
    }

    #if os(macOS)
    private func delete(tradeIds: Set<Trade.ID>) {
        withAnimation {
            for tradeId in tradeIds {
                delete(tradeId: tradeId)
            }
            try? modelContext.saveIfNeeded()
        }
    }
    #endif

    private func deleteItems(offsets: IndexSet) {
        let tradeIDs = offsets.map { visibleTrades[$0].id }

        withAnimation {
            for tradeID in tradeIDs {
                delete(tradeId: tradeID)
            }
            try? modelContext.saveIfNeeded()
        }
    }

    private func deleteFromDetail(tradeId: Trade.ID) {
        withAnimation {
            delete(tradeId: tradeId)
            try? modelContext.saveIfNeeded()
        }
    }

    #if os(macOS)
    private func keepSelectionInSync() {
        let visibleTradeIDs = Set(visibleTrades.map(\.id))
        selectedTradeIDs.formIntersection(visibleTradeIDs)

        if !selectedTradeIDs.isEmpty {
            return
        }

        if let firstVisibleTradeID = visibleTrades.first?.id {
            selectedTradeIDs = [firstVisibleTradeID]
        }
    }
    #endif

    private func resetFilters() {
        filters.resetSelections()
    }
}

#Preview {
    TradeJournalView()
}
