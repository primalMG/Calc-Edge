import SwiftUI
import SwiftData

struct SetupPlaybookView: View {
    var body: some View {
        NavigationStack {
            SetupPlaybookContent()
        }
    }
}

struct SetupPlaybookContent: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TradingSetup.updatedAt, order: .reverse) private var setups: [TradingSetup]

    @State private var toast: ToastConfiguration?

    var body: some View {
        content
            .navigationTitle("Playbook")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: addSetup) {
                        Label("New Setup", systemImage: "plus")
                    }
                    .help("New Setup")
                }
            }
            .toast($toast)
            .navigationDestination(for: SetupPlaybookRoute.self) { route in
                switch route {
                case .setup(let setupID):
                    if let setup = setup(with: setupID) {
                        SetupDetailView(setup: setup)
                    } else {
                        ContentUnavailableView("Setup Not Found", systemImage: "rectangle.stack")
                    }
                }
            }
    }

    @ViewBuilder
    private var content: some View {
        if setups.isEmpty {
            ContentUnavailableView(
                "No Setups Yet",
                systemImage: "rectangle.stack.badge.plus",
                description: Text("Create setup definitions and compare them with your journal results.")
            )
        } else {
            List {
                ForEach(setups) { setup in
                    HStack(spacing: 12) {
                        NavigationLink {
                            SetupDetailView(setup: setup)
                        } label: {
                            SetupRow(setup: setup)
                        }

                        #if os(macOS)
                        Button(role: .destructive) {
                            deleteSetup(setup)
                        } label: {
                            Label("Delete Setup", systemImage: "trash")
                                .labelStyle(.iconOnly)
                        }
                        .buttonStyle(.borderless)
                        .help("Delete Setup")
                        #endif
                    }
                }
                #if os(iOS)
                .onDelete(perform: deleteSetups)
                #endif
            }
        }
    }

    private func addSetup() {
        let setup = TradingSetup(name: "New Setup")
        modelContext.insert(setup)
        toast = ToastConfiguration(title: "Setup Created", message: "Add criteria, invalidation, and notes.", state: .success)
    }

    private func deleteSetups(at offsets: IndexSet) {
        for index in offsets {
            deleteSetup(setups[index])
        }
    }

    private func deleteSetup(_ setup: TradingSetup) {
        modelContext.delete(setup)
    }

    private func setup(with setupID: UUID) -> TradingSetup? {
        setups.first { $0.setupId == setupID }
    }
}

private enum SetupPlaybookRoute: Hashable {
    case setup(UUID)
}

private struct SetupRow: View {
    let setup: TradingSetup

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(setup.name.isEmpty ? "Untitled Setup" : setup.name)
                    .font(.headline)

                Spacer()

                if !setup.isActive {
                    Text("Paused")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(metadata)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            if let criteria = setup.criteria, !criteria.isEmpty {
                Text(criteria)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private var metadata: String {
        [setup.strategyName, setup.timeframe, setup.catalyst]
            .compactMap { value in
                guard let value, !value.isEmpty else { return nil }
                return value
            }
            .joined(separator: " · ")
    }
}

private struct SetupDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var setup: TradingSetup
    @Query private var trades: [Trade]

    var body: some View {
        Form {
            PlaybookFormSection("Definition") {
                TextField("Setup Name", text: $setup.name)
                TextField("Strategy", text: optionalTextBinding($setup.strategyName))
                TextField("Timeframe", text: optionalTextBinding($setup.timeframe))
                TextField("Catalyst", text: optionalTextBinding($setup.catalyst))
                Toggle("Active", isOn: $setup.isActive)
            }

            PlaybookFormSection("A+ Criteria") {
                TextField("What must be true before taking this setup?", text: optionalTextBinding($setup.criteria), axis: .vertical)
                    .lineLimit(3...8)
            }

            PlaybookFormSection("Invalidation") {
                TextField("What tells you this setup is no longer valid?", text: optionalTextBinding($setup.invalidation), axis: .vertical)
                    .lineLimit(2...6)
            }

            PlaybookFormSection("Notes") {
                TextField("Examples, reminders, or screenshots to add later", text: optionalTextBinding($setup.notes), axis: .vertical)
                    .lineLimit(2...8)
            }

            PlaybookFormSection("Journal Stats") {
                SetupPerformanceSummary(setup: setup, trades: matchingTrades)
            }

            if !matchingTrades.isEmpty {
                PlaybookFormSection("Matching Trades") {
                    ForEach(matchingTrades.prefix(8)) { trade in
                        NavigationLink {
                            TradeJournalDetailView(trade: trade)
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(trade.ticker)
                                    .font(.headline)
                                Text(trade.openedAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle(setup.name.isEmpty ? "Setup" : setup.name)
        .onTradingSetupChange(setup, perform: markUpdated)
    }

    private var matchingTrades: [Trade] {
        trades
            .filter(matchesSetup)
            .sorted { $0.openedAt > $1.openedAt }
    }

    private func matchesSetup(_ trade: Trade) -> Bool {
        matches(setup.name, trade.setupType)
            || matches(setup.strategyName, trade.strategyName)
            || matches(setup.timeframe, trade.timeframe)
            || matches(setup.catalyst, trade.catalyst)
    }

    private func matches(_ lhs: String?, _ rhs: String?) -> Bool {
        guard let lhs = lhs?.trimmingCharacters(in: .whitespacesAndNewlines),
              let rhs = rhs?.trimmingCharacters(in: .whitespacesAndNewlines),
              !lhs.isEmpty,
              !rhs.isEmpty else {
            return false
        }

        return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedSame
    }

    private func markUpdated() {
        setup.updatedAt = .now
        try? modelContext.save()
    }
}

private struct PlaybookFormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        Section {
            content
        } header: {
            Text(title)
                .font(.headline)
                .padding(.bottom, 4)
        }
        .padding(.bottom, 12)
    }
}

private extension View {
    func onTradingSetupChange(_ setup: TradingSetup, perform action: @escaping () -> Void) -> some View {
        self
            .onChange(of: setup.name) { _, _ in action() }
            .onChange(of: setup.strategyName) { _, _ in action() }
            .onChange(of: setup.timeframe) { _, _ in action() }
            .onChange(of: setup.catalyst) { _, _ in action() }
            .onChange(of: setup.criteria) { _, _ in action() }
            .onChange(of: setup.invalidation) { _, _ in action() }
            .onChange(of: setup.notes) { _, _ in action() }
            .onChange(of: setup.isActive) { _, _ in action() }
    }
}

private struct SetupPerformanceSummary: View {
    let setup: TradingSetup
    let trades: [Trade]

    var body: some View {
        let insights = TradeInsightsCalculator(trades: trades).calculate()

        LazyVGrid(columns: columns, spacing: 12) {
            InfoStatCard(title: "Trades", value: "\(trades.count)")
            InfoStatCard(title: "Win Rate", value: JournalInsightsFormatting.percentage(insights.winRate))
            InfoStatCard(title: "Expectancy", value: JournalInsightsFormatting.rMultiple(insights.expectancy))
            InfoStatCard(title: "A+ Rate", value: JournalInsightsFormatting.percentage(aPlusRate))
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 140), spacing: 12)]
    }

    private var aPlusRate: Double? {
        guard !trades.isEmpty else { return nil }
        let aPlusCount = trades.filter(\.isAPlusSetup).count
        return Double(aPlusCount) / Double(trades.count)
    }
}

#Preview {
    SetupPlaybookView()
        .modelContainer(for: [TradingSetup.self, Trade.self, TradeReview.self], inMemory: true)
}

