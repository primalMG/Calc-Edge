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

    @State private var toast: ToastConfiguration?

    var body: some View {
        content
            .navigationTitle("Rulebook")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: addRule) {
                        Label("New Rule", systemImage: "plus")
                    }
                    .help("New Rule")
                }
            }
            .toast($toast)
<<<<<<< HEAD
            .navigationDestination(for: RulebookRoute.self) { route in
                switch route {
                case .rule(let ruleID):
                    if let rule = rule(with: ruleID) {
                        RuleDetailView(rule: rule)
                    } else {
                        ContentUnavailableView("Rule Not Found", systemImage: "checklist.checked")
                    }
                }
            }
=======
>>>>>>> first-branch
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
            List {
                ForEach(rules) { rule in
                    NavigationLink {
                        RuleDetailView(rule: rule)
                    } label: {
<<<<<<< HEAD
                        RuleRow(rule: rule) {
                            deleteRule(rule)
                        }
                    }
                }
                #if os(iOS)
                .onDelete(perform: deleteRules)
                #endif
=======
                        RuleRow(rule: rule)
                    }
                }
                .onDelete(perform: deleteRules)
>>>>>>> first-branch
            }
        }
    }

    private func addRule() {
        let rule = TradingRule(title: "New Rule", category: "Process")
        modelContext.insert(rule)
        toast = ToastConfiguration(title: "Rule Created", message: "Edit the title and checklist prompt.", state: .success)
    }

    private func deleteRules(at offsets: IndexSet) {
        for index in offsets {
<<<<<<< HEAD
            deleteRule(rules[index])
        }
    }

    private func deleteRule(_ rule: TradingRule) {
        modelContext.delete(rule)
    }

    private func rule(with ruleID: UUID) -> TradingRule? {
        rules.first { $0.ruleId == ruleID }
    }
}

private enum RulebookRoute: Hashable {
    case rule(UUID)
=======
            modelContext.delete(rules[index])
        }
    }
>>>>>>> first-branch
}

private struct RuleRow: View {
    let rule: TradingRule
<<<<<<< HEAD
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
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

            #if os(macOS)
            Button(role: .destructive, action: onDelete) {
                Label("Delete Rule", systemImage: "trash")
                    .labelStyle(.iconOnly)
            }
            .buttonStyle(.borderless)
            .help("Delete Rule")
            #endif
=======

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
>>>>>>> first-branch
        }
        .padding(.vertical, 4)
    }
}

private struct RuleDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var rule: TradingRule
    @Query private var trades: [Trade]

    var body: some View {
        Form {
<<<<<<< HEAD
            RulebookFormSection("Rule") {
=======
            Section("Rule") {
>>>>>>> first-branch
                TextField("Title", text: $rule.title)
                TextField("Category", text: $rule.category)
                Toggle("Active", isOn: $rule.isActive)
            }

<<<<<<< HEAD
            RulebookFormSection("Checklist") {
=======
            Section("Checklist") {
>>>>>>> first-branch
                TextField("Prompt shown during trade review", text: optionalTextBinding($rule.checklistPrompt), axis: .vertical)
                    .lineLimit(2...4)
            }

<<<<<<< HEAD
            RulebookFormSection("Description") {
=======
            Section("Description") {
>>>>>>> first-branch
                TextField("Why this rule matters", text: optionalTextBinding($rule.ruleDescription), axis: .vertical)
                    .lineLimit(3...8)
            }

<<<<<<< HEAD
            RulebookFormSection("Performance") {
                RulePerformanceSummary(rule: rule, trades: trades)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .navigationTitle(rule.title.isEmpty ? "Rule" : rule.title)
        .onTradingRuleChange(rule, perform: markUpdated)
=======
            Section("Performance") {
                RulePerformanceSummary(rule: rule, trades: trades)
            }
        }
        .navigationTitle(rule.title.isEmpty ? "Rule" : rule.title)
        .onChange(of: rule.title) { _, _ in markUpdated() }
        .onChange(of: rule.category) { _, _ in markUpdated() }
        .onChange(of: rule.ruleDescription) { _, _ in markUpdated() }
        .onChange(of: rule.checklistPrompt) { _, _ in markUpdated() }
        .onChange(of: rule.isActive) { _, _ in markUpdated() }
>>>>>>> first-branch
    }

    private func markUpdated() {
        rule.updatedAt = .now
        try? modelContext.save()
    }
}

<<<<<<< HEAD
private struct RulebookFormSection<Content: View>: View {
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
    func onTradingRuleChange(_ rule: TradingRule, perform action: @escaping () -> Void) -> some View {
        self
            .onChange(of: rule.title) { _, _ in action() }
            .onChange(of: rule.category) { _, _ in action() }
            .onChange(of: rule.ruleDescription) { _, _ in action() }
            .onChange(of: rule.checklistPrompt) { _, _ in action() }
            .onChange(of: rule.isActive) { _, _ in action() }
    }
}

=======
>>>>>>> first-branch
private struct RulePerformanceSummary: View {
    let rule: TradingRule
    let trades: [Trade]

    var body: some View {
        let checks = rule.checks ?? []
        let followed = checks.filter(\.followed)
        let broken = checks.filter { !$0.followed }

        LazyVGrid(columns: columns, spacing: 12) {
            InfoStatCard(title: "Checked", value: "\(checks.count)")
            InfoStatCard(title: "Followed", value: percentage(followed.count, checks.count))
            InfoStatCard(title: "Broken", value: "\(broken.count)", accentColor: broken.isEmpty ? .green : .orange)
            InfoStatCard(title: "Avg R When Followed", value: averageR(for: followed))
        }
    }

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 140), spacing: 12)]
    }

    private func percentage(_ count: Int, _ total: Int) -> String {
        guard total > 0 else { return "No data" }
        return "\(Int((Double(count) / Double(total) * 100).rounded()))%"
    }

    private func averageR(for checks: [TradeRuleCheck]) -> String {
        let calculator = TradeInsightsCalculator(trades: checks.compactMap { $0.review?.trade })
        let values = checks.compactMap { check -> Double? in
            guard let trade = check.review?.trade else { return nil }
            return calculator.rMultiple(for: trade)
        }
        guard !values.isEmpty else { return "No data" }
        let total = values.reduce(0, +)
        let average = total / Double(values.count)
        return "\(average.formatted(.number.precision(.fractionLength(2))))R"
    }
}

#Preview {
    RulebookView()
        .modelContainer(for: [TradingRule.self, TradeRuleCheck.self, Trade.self, TradeReview.self], inMemory: true)
}
