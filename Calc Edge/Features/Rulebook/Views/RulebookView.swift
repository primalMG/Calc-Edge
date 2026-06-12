import SwiftUI
import SwiftData

struct RulebookView: View {
    var body: some View {
        NavigationStack {
            RulebookContent()
        }
    }
}

struct RulebookContent: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TradingRule.updatedAt, order: .reverse) private var rules: [TradingRule]

    @State private var selectedRuleID: UUID?
    #if os(iOS)
    @State private var presentedRule: TradingRule?
    #endif
    @State private var toast: ToastConfiguration?

    var body: some View {
        content
            .navigationTitle("Rulebook")
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive, action: deleteSelectedRule) {
                        Label("Delete Rule", systemImage: "trash")
                    }
                    .disabled(selectedRule == nil)
                    .help("Delete Selected Rule")
                }
                #endif

                ToolbarItem(placement: .automatic) {
                    Button(action: addRule) {
                        #if os(macOS)
                        Image(systemName: "square.and.pencil")
                        #else
                        Label("New Rule", systemImage: "plus")
                        #endif
                    }
                    .help("New Rule")
                }
            }
            .toast($toast)
            #if os(iOS)
            .sheet(item: $presentedRule) { rule in
                NavigationStack {
                    RuleDetailView(rule: rule)
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            #endif
            .onAppear(perform: keepSelectionInSync)
            .onChange(of: rules.map(\.ruleId)) { _, _ in
                keepSelectionInSync()
            }
    }

    @ViewBuilder
    private var content: some View {
        if rules.isEmpty {
            ContentUnavailableView(
                "No Rules Yet",
                systemImage: "checklist.checked",
                description: Text("Create rules for entries, exits, risk, and review discipline.")
            )
        } else {
            #if os(macOS)
            HSplitView {
                ruleList
                    .frame(width: 300)

                ruleDetail
                    .frame(minWidth: 420, idealWidth: 620)
            }
            #else
            ruleList
            #endif
        }
    }

    private var ruleList: some View {
        List {
            ForEach(rules) { rule in
                #if os(macOS)
                Button {
                    selectedRuleID = rule.ruleId
                } label: {
                    RuleRow(rule: rule)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .listRowBackground(selectedRuleID == rule.ruleId ? Color.accentColor.opacity(0.12) : nil)
                #else
                Button {
                    presentedRule = rule
                } label: {
                    RuleRow(rule: rule)
                }
                .buttonStyle(.plain)
                #endif
            }
            #if os(iOS)
            .onDelete(perform: deleteRules)
            #endif
        }
    }

    #if os(macOS)
    @ViewBuilder
    private var ruleDetail: some View {
        if let selectedRule {
            RuleDetailView(rule: selectedRule)
        } else {
            ContentUnavailableView("Select a Rule", systemImage: "checklist.checked")
        }
    }
    #endif

    private var selectedRule: TradingRule? {
        guard let selectedRuleID else { return nil }
        return rule(with: selectedRuleID)
    }

    private func rule(with ruleID: UUID) -> TradingRule? {
        rules.first(where: { $0.ruleId == ruleID })
    }

    private func keepSelectionInSync() {
        guard !rules.isEmpty else {
            selectedRuleID = nil
            return
        }

        if let selectedRuleID,
           rules.contains(where: { $0.ruleId == selectedRuleID }) {
            return
        }

        #if os(macOS)
        selectedRuleID = rules.first?.ruleId
        #else
        selectedRuleID = nil
        #endif
    }

    private func addRule() {
        let rule = TradingRule(title: "New Rule", category: "Process")
        modelContext.insert(rule)
        #if os(macOS)
        selectedRuleID = rule.ruleId
        #else
        presentedRule = rule
        #endif
        toast = ToastConfiguration(title: "Rule Created", message: "Edit the title and checklist prompt.", state: .success)
    }

    private func deleteRules(at offsets: IndexSet) {
        for index in offsets {
            deleteRule(rules[index])
        }
    }

    private func deleteSelectedRule() {
        guard let selectedRule else { return }
        deleteRule(selectedRule)
    }

    private func deleteRule(_ rule: TradingRule) {
        if selectedRuleID == rule.ruleId {
            selectedRuleID = nil
        }
        #if os(iOS)
        if presentedRule?.ruleId == rule.ruleId {
            presentedRule = nil
        }
        #endif
        modelContext.delete(rule)
        keepSelectionInSync()
        try? modelContext.saveIfNeeded()
    }
}

private struct RuleRow: View {
    let rule: TradingRule

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(rule.title.isEmpty ? "Untitled Rule" : rule.title)
                    .font(.headline)

                Spacer()

                if !rule.isActive {
                    Text("Paused")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Text(rule.category.isEmpty ? "Uncategorised" : rule.category)
                .font(.caption)
                .foregroundStyle(.secondary)

            if let prompt = rule.checklistPrompt, !prompt.isEmpty {
                Text(prompt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct RuleDetailView: View {
    #if os(iOS)
    @Environment(\.dismiss) private var dismiss
    #endif
    @Environment(\.modelContext) private var modelContext
    @Bindable var rule: TradingRule

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                RulebookFormSection("Rule") {
                    TextField("Title", text: $rule.title)
                    TextField("Category", text: $rule.category)
                    Toggle("Active", isOn: $rule.isActive)
                }

                RulebookFormSection("Checklist") {
                    TextField("Prompt shown during trade review", text: optionalTextBinding($rule.checklistPrompt), axis: .vertical)
                        .lineLimit(2...4)
                }

                RulebookFormSection("Description") {
                    TextField("Why this rule matters", text: optionalTextBinding($rule.ruleDescription), axis: .vertical)
                        .lineLimit(3...8)
                }

                RulebookFormSection("Performance") {
                    RulePerformanceSummary(rule: rule)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle(rule.title.isEmpty ? "Rule" : rule.title)
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        #endif
        .onDebouncedChange(of: TradingRuleEditSnapshot(rule: rule), perform: markUpdated)
    }

    private func markUpdated() {
        rule.updatedAt = .now
        try? modelContext.save()
    }
}

private struct RulebookFormSection<Content: View>: View {
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
    RulebookView()
        .modelContainer(for: [TradingRule.self, TradeRuleCheck.self, Trade.self, TradeReview.self], inMemory: true)
}
