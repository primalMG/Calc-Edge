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
    @State private var presentedDraft: JournalDraftPresentation?
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
            .sheet(item: $presentedDraft) { draft in
                NewJournalView(trade: draft.trade, isNew: true)
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
        .fileImporter(isPresented: $showFileImporter,
                      allowedContentTypes: [.commaSeparatedText, .plainText],
                      allowsMultipleSelection: false) { result in
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
        presentedDraft = JournalDraftPresentation(trade: Trade(ticker: ""))
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
            if let trade = trades.first {
                presentedDraft = JournalDraftPresentation(trade: trade)
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

private struct JournalDraftPresentation: Identifiable {
    let id = UUID()
    let trade: Trade
}

private struct ImportAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

#if os(macOS)
private struct TradeJournalTable: View {
    let trades: [Trade]
    @Binding var selectedTradeID: Trade.ID?
    @Binding var sortOrder: [KeyPathComparator<Trade>]
    let deleteTrade: (Trade.ID) -> Void

    var body: some View {
        Table(trades, selection: $selectedTradeID, sortOrder: $sortOrder) {
            TableColumn("Opened At") { trade in
                Text(TradeJournalFormatting.date(trade.openedAt))
            }

            TableColumn("Ticker") { trade in
                Text(TradeJournalFormatting.title(for: trade))
            }

            TableColumn("Direction") { trade in
                Text(TradeJournalFormatting.displayText(trade.direction.rawValue))
                    .foregroundStyle(trade.direction.rawValue == "long" ? Color.green : Color.red)
            }

            TableColumn("Instrument") { trade in
                Text(TradeJournalFormatting.displayText(trade.instrument.rawValue))
            }

            TableColumn("Entry Price") { trade in
                Text(TradeJournalFormatting.decimal(trade.entryPrice))
            }

            TableColumn("Exit") { trade in
                VStack(alignment: .leading, spacing: 2) {
                    Text(TradeJournalFormatting.exitStatus(for: trade))
                    HStack(spacing: 6) {
                        Text("Price: \(TradeJournalFormatting.decimal(trade.exitPrice))")
                        Text("Reason: \(TradeJournalFormatting.exitReason(for: trade))")
                    }
                    .foregroundStyle(.secondary)
                }
            }

            TableColumn("Confidence") { trade in
                Text("\(trade.confidenceScore)")
            }
        }
        .contextMenu(forSelectionType: Trade.ID.self) { items in
            if let tradeID = items.first {
                Button("Delete Trade", role: .destructive) {
                    deleteTrade(tradeID)
                }
            }
        }
    }
}
#endif

#if os(iOS)
private struct TradeJournalList: View {
    let trades: [Trade]
    let deleteItems: (IndexSet) -> Void

    var body: some View {
        List {
            ForEach(trades) { trade in
                NavigationLink {
                    TradeJournalDetailView(trade: trade)
                } label: {
                    TradeJournalRow(trade: trade)
                }
            }
            .onDelete(perform: deleteItems)
        }
    }
}
#endif

private struct TradeJournalRow: View {
    let trade: Trade

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(TradeJournalFormatting.title(for: trade))
                    .font(.headline)

                Spacer()

                Text(TradeJournalFormatting.date(trade.openedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                Label(
                    TradeJournalFormatting.displayText(trade.direction.rawValue),
                    systemImage: trade.direction == .long ? "arrow.up.forward" : "arrow.down.forward"
                )
                .foregroundStyle(trade.direction.rawValue == "long" ? Color.green : Color.red)
                
                Label(
                    TradeJournalFormatting.displayText(trade.instrument.rawValue),
                    systemImage: "chart.line.uptrend.xyaxis"
                )
            }
            .font(.subheadline)
            
            if let account = trade.account,
               !account.isEmpty {
                Label(account, systemImage: "person.crop.circle")
            }

            HStack(spacing: 12) {
                Text("Entry \(TradeJournalFormatting.decimal(trade.entryPrice))")
                Text(TradeJournalFormatting.exitStatus(for: trade))
                Text("Confidence \(trade.confidenceScore)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            if trade.closedAt != nil && trade.exitPrice != nil {
                Text("Exit \(TradeJournalFormatting.decimal(trade.exitPrice))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

private enum TradeJournalFormatting {
    static func title(for trade: Trade) -> String {
        let ticker = trade.ticker.trimmingCharacters(in: .whitespacesAndNewlines)
        return ticker.isEmpty ? "Untitled Trade" : ticker
    }

    static func date(_ date: Date) -> String {
        date.formatted(date: .abbreviated, time: .shortened)
    }

    static func decimal(_ value: Decimal?) -> String {
        guard let value else { return "N/A" }
        return NSDecimalNumber(decimal: value).stringValue
    }

    static func exitStatus(for trade: Trade) -> String {
        if let closedAt = trade.closedAt {
            return "Closed \(date(closedAt))"
        }

        return "Open Trade"
    }

    static func exitReason(for trade: Trade) -> String {
        guard let exitReason = trade.exitReason else {
            return "N/A"
        }

        return displayText(exitReason.rawValue)
    }

    static func displayText(_ rawValue: String) -> String {
        let separatedWords = rawValue.replacingOccurrences(
            of: "([a-z])([A-Z])",
            with: "$1 $2",
            options: .regularExpression
        )
        return separatedWords.capitalized
    }
}

private struct TradeJournalFilters {
    var tickerQuery = ""
    var date: TradeDateFilter = .all
    var direction: DirectionFilter = .all
    var instrument: InstrumentFilter = .all

    var normalizedTickerQuery: String {
        tickerQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var hasActiveFilters: Bool {
        date != .all || direction != .all || instrument != .all
    }

    func matches(_ trade: Trade) -> Bool {
        if !normalizedTickerQuery.isEmpty &&
            !trade.ticker.localizedCaseInsensitiveContains(normalizedTickerQuery) {
            return false
        }

        guard date.matches(trade.openedAt) else {
            return false
        }

        guard direction.matches(trade.direction) else {
            return false
        }

        return instrument.matches(trade.instrument)
    }

    mutating func resetSelections() {
        date = .all
        direction = .all
        instrument = .all
    }
}

private enum TradeDateFilter: String, CaseIterable, Identifiable {
    case all
    case today
    case last7Days
    case last30Days
    case thisMonth
    case thisYear

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All Dates"
        case .today:
            return "Today"
        case .last7Days:
            return "Last 7 Days"
        case .last30Days:
            return "Last 30 Days"
        case .thisMonth:
            return "This Month"
        case .thisYear:
            return "This Year"
        }
    }

    func matches(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let now = Date.now

        switch self {
        case .all:
            return true
        case .today:
            return calendar.isDateInToday(date)
        case .last7Days:
            guard let cutoff = calendar.date(byAdding: .day, value: -7, to: now) else {
                return true
            }
            return date >= cutoff
        case .last30Days:
            guard let cutoff = calendar.date(byAdding: .day, value: -30, to: now) else {
                return true
            }
            return date >= cutoff
        case .thisMonth:
            return calendar.isDate(date, equalTo: now, toGranularity: .month)
        case .thisYear:
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
        }
    }
}

private enum DirectionFilter: String, CaseIterable, Identifiable {
    case all
    case long
    case short

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All Directions"
        case .long:
            return "Long"
        case .short:
            return "Short"
        }
    }

    func matches(_ direction: TradeDirection) -> Bool {
        switch self {
        case .all:
            return true
        case .long:
            return direction == .long
        case .short:
            return direction == .short
        }
    }
}

private enum InstrumentFilter: String, CaseIterable, Identifiable {
    case all
    case stock
    case etf
    case option
    case future
    case forex
    case crypto
    case cfd
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all:
            return "All Instruments"
        case .stock:
            return "Stock"
        case .etf:
            return "ETF"
        case .option:
            return "Option"
        case .future:
            return "Future"
        case .forex:
            return "Forex"
        case .crypto:
            return "Crypto"
        case .cfd:
            return "CFD"
        case .other:
            return "Other"
        }
    }

    func matches(_ instrument: InstrumentType) -> Bool {
        switch self {
        case .all:
            return true
        case .stock:
            return instrument == .stock
        case .etf:
            return instrument == .etf
        case .option:
            return instrument == .option
        case .future:
            return instrument == .future
        case .forex:
            return instrument == .forex
        case .crypto:
            return instrument == .crypto
        case .cfd:
            return instrument == .cfd
        case .other:
            return instrument == .other
        }
    }
}

#Preview {
    TradeJournalView()
}
