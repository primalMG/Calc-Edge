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

    @State private var selectedSetupID: UUID?
    #if os(iOS)
    @State private var presentedSetup: TradingSetup?
    #endif
    @State private var toast: ToastConfiguration?

    var body: some View {
        content
            .navigationTitle("Playbook")
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive, action: deleteSelectedSetup) {
                        Label("Delete Setup", systemImage: "trash")
                    }
                    .disabled(selectedSetup == nil)
                    .help("Delete Selected Setup")
                }
                #endif

                ToolbarItem(placement: .automatic) {
                    Button(action: addSetup) {
                        #if os(macOS)
                        Image(systemName: "square.and.pencil")
                        #else
                        Label("New Setup", systemImage: "plus")
                        #endif
                    }
                    .accessibilityLabel("New Setup")
                    .help("New Setup")
                }
            }
            .toast($toast)
            #if os(iOS)
            .sheet(item: $presentedSetup) { setup in
                NavigationStack {
                    SetupDetailView(setup: setup)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            #endif
            .onAppear(perform: keepSelectionInSync)
            .onChange(of: setups.map(\.setupId)) { _, _ in
                keepSelectionInSync()
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
            #if os(macOS)
            HSplitView {
                setupList
                    .frame(width: 300)

                setupDetail
                    .frame(minWidth: 460, idealWidth: 700)
            }
            #else
            setupList
            #endif
        }
    }

    private var setupList: some View {
        List {
            ForEach(setups) { setup in
                #if os(macOS)
                Button {
                    selectedSetupID = setup.setupId
                } label: {
                    SetupRow(setup: setup)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .listRowBackground(selectedSetupID == setup.setupId ? Color.accentColor.opacity(0.12) : nil)
                #else
                Button {
                    presentedSetup = setup
                } label: {
                    SetupRow(setup: setup)
                }
                .buttonStyle(.plain)
                #endif
            }
            #if os(iOS)
            .onDelete(perform: deleteSetups)
            #endif
        }
    }

    #if os(macOS)
    @ViewBuilder
    private var setupDetail: some View {
        if let selectedSetup {
            SetupDetailView(setup: selectedSetup)
        } else {
            ContentUnavailableView("Select a Setup", systemImage: "rectangle.stack.badge.plus")
        }
    }
    #endif

    private var selectedSetup: TradingSetup? {
        guard let selectedSetupID else { return nil }
        return setup(with: selectedSetupID)
    }

    private func setup(with setupID: UUID) -> TradingSetup? {
        setups.first(where: { $0.setupId == setupID })
    }

    private func keepSelectionInSync() {
        guard !setups.isEmpty else {
            selectedSetupID = nil
            return
        }

        if let selectedSetupID,
           setups.contains(where: { $0.setupId == selectedSetupID }) {
            return
        }

        #if os(macOS)
        selectedSetupID = setups.first?.setupId
        #else
        selectedSetupID = nil
        #endif
    }

    private func addSetup() {
        let setup = TradingSetup(name: "New Setup")
        modelContext.insert(setup)
        #if os(macOS)
        selectedSetupID = setup.setupId
        #else
        presentedSetup = setup
        #endif
        toast = ToastConfiguration(title: "Setup Created", message: "Add criteria, invalidation, and notes.", state: .success)
    }

    private func deleteSetups(at offsets: IndexSet) {
        for index in offsets {
            deleteSetup(setups[index])
        }
    }

    private func deleteSelectedSetup() {
        guard let selectedSetup else { return }
        deleteSetup(selectedSetup)
    }

    private func deleteSetup(_ setup: TradingSetup) {
        if selectedSetupID == setup.setupId {
            selectedSetupID = nil
        }
        #if os(iOS)
        if presentedSetup?.setupId == setup.setupId {
            presentedSetup = nil
        }
        #endif
        modelContext.delete(setup)
        keepSelectionInSync()
        try? modelContext.saveIfNeeded()
    }
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
    #if os(iOS)
    @Environment(\.dismiss) private var dismiss
    #endif
    @Environment(\.modelContext) private var modelContext
    @Bindable var setup: TradingSetup

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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

                SetupPlaybookTradeMatches(setup: setup)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle(setup.name.isEmpty ? "Setup" : setup.name)
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        #endif
        .onDebouncedChange(of: TradingSetupEditSnapshot(setup: setup), perform: markUpdated)
    }

    private func markUpdated() {
        setup.updatedAt = .now
        try? modelContext.save()
    }
}

struct PlaybookFormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        FormSectionContainer(title, style: .standard) {
            content
        }
    }
}

#Preview {
    SetupPlaybookView()
        .modelContainer(for: [TradingSetup.self, Trade.self, TradeReview.self], inMemory: true)
}
