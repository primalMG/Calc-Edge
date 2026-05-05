import SwiftUI
import SwiftData

struct TransactionsSection: View {
    @Environment(\.modelContext) private var modelContext

    @Bindable var trade: Trade

    @State private var editorState: TradeTransactionEditorState?

    private var transactions: [TradeTransaction] {
        (trade.transactions ?? []).sorted { $0.date > $1.date }
    }

    var body: some View {
        JournalSectionContainer("Transactions") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(transactionSummary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 12)

                    Button {
                        editorState = .new()
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                    #if os(iOS)
                    .buttonStyle(.borderedProminent)
                    #endif
                }

                if transactions.isEmpty {
                    Text("No transactions added yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(transactions) { transaction in
                            TradeTransactionRow(transaction: transaction) {
                                editorState = .edit(transaction)
                            } onDelete: {
                                remove(transaction)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(item: $editorState) { state in
            TradeTransactionEditorSheet(state: state) { draft in
                save(draft, for: state.transaction)
            }
        }
    }

    private var transactionSummary: String {
        guard !transactions.isEmpty else {
            return "Buys, sells, adds, trims, dividends, and fees"
        }

        return "\(transactions.count) transaction\(transactions.count == 1 ? "" : "s")"
    }

    private func save(_ draft: TradeTransactionDraft, for transaction: TradeTransaction?) {
        let previousSummary = trade.positionSummary
        let wasNew = transaction == nil
        let previousTransactionSummary = transaction.map(transactionSummary(for:))
        let transaction = transaction ?? TradeTransaction(
            date: draft.date,
            action: draft.action,
            quantity: draft.quantity,
            price: draft.price,
            exchangeRate: draft.exchangeRate,
            fees: draft.fees,
            note: draft.note
        )

        transaction.date = draft.date
        transaction.action = draft.action
        transaction.quantity = draft.quantity
        transaction.price = draft.price
        transaction.exchangeRate = draft.exchangeRate
        transaction.fees = draft.fees
        transaction.note = draft.note

        if transaction.trade == nil {
            if trade.transactions == nil {
                trade.transactions = []
            }

            trade.transactions?.append(transaction)
        }

        trade.appendValueChangeLog(
            summary: wasNew ? "Added \(draft.action.displayName) transaction" : "Edited \(draft.action.displayName) transaction",
            detail: changeLogDetail(
                previous: previousTransactionSummary,
                current: transactionSummary(for: transaction)
            ),
            previous: previousSummary,
            current: trade.positionSummary
        )
    }

    private func remove(_ transaction: TradeTransaction) {
        let previousSummary = trade.positionSummary
        let removedTransactionSummary = transactionSummary(for: transaction)

        if let index = trade.transactions?.firstIndex(where: { $0 === transaction }) {
            trade.transactions?.remove(at: index)
        }

        modelContext.delete(transaction)

        trade.appendValueChangeLog(
            summary: "Deleted \(transaction.action.displayName) transaction",
            detail: removedTransactionSummary,
            previous: previousSummary,
            current: trade.positionSummary
        )
    }

    private func transactionSummary(for transaction: TradeTransaction) -> String {
        var summary = "\(transaction.action.displayName) \(ValueDisplayFormatter.decimal(transaction.quantity)) @ \(ValueDisplayFormatter.decimal(transaction.price))"

        if let exchangeRate = transaction.exchangeRate {
            summary += " FX \(ValueDisplayFormatter.decimal(exchangeRate))"
        }

        return summary
    }

    private func changeLogDetail(previous: String?, current: String) -> String {
        guard let previous, previous != current else {
            return current
        }

        return "\(previous) -> \(current)"
    }
}

private struct TradeTransactionRow: View {
    @Bindable var transaction: TradeTransaction
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: transaction.action.systemImage)
                .font(.headline)
                .foregroundStyle(transaction.action.tint)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(transaction.action.displayName)
                        .font(.headline)

                    Text(transaction.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(transactionDetail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if let note = transaction.note?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 8)

            Button(action: onEdit) {
                Image(systemName: "pencil")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Edit transaction")

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Delete transaction")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
    }

    private var transactionDetail: String {
        let quantity = ValueDisplayFormatter.decimal(transaction.quantity)
        let price = ValueDisplayFormatter.decimal(transaction.price)
        let base = "\(quantity) @ \(price)"

        var details = [base]

        if let exchangeRate = transaction.exchangeRate {
            details.append("FX \(ValueDisplayFormatter.decimal(exchangeRate))")
        }

        if let fees = transaction.fees {
            details.append("Fees \(ValueDisplayFormatter.decimal(fees))")
        }

        return details.joined(separator: " | ")
    }
}

struct TradeTransactionEditorState: Identifiable {
    let id = UUID()
    let transaction: TradeTransaction?
    let draft: TradeTransactionDraft

    static func new() -> TradeTransactionEditorState {
        TradeTransactionEditorState(
            transaction: nil,
            draft: TradeTransactionDraft()
        )
    }

    static func edit(_ transaction: TradeTransaction) -> TradeTransactionEditorState {
        TradeTransactionEditorState(
            transaction: transaction,
            draft: TradeTransactionDraft(transaction: transaction)
        )
    }
}

struct TradeTransactionDraft {
    var date: Date = .now
    var action: TradeTransactionAction = .buy
    var quantity: Decimal = 0
    var price: Decimal = 0
    var exchangeRate: Decimal?
    var fees: Decimal?
    var note: String?

    init() {}

    init(transaction: TradeTransaction) {
        date = transaction.date
        action = transaction.action
        quantity = transaction.quantity
        price = transaction.price
        exchangeRate = transaction.exchangeRate
        fees = transaction.fees
        note = transaction.note
    }
}

private struct TradeTransactionEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: TradeTransactionDraft

    let state: TradeTransactionEditorState
    let onSave: (TradeTransactionDraft) -> Void

    init(
        state: TradeTransactionEditorState,
        onSave: @escaping (TradeTransactionDraft) -> Void
    ) {
        self.state = state
        self.onSave = onSave
        _draft = State(initialValue: state.draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $draft.date, displayedComponents: [.date])

                    Picker("Action", selection: $draft.action) {
                        ForEach(TradeTransactionAction.allCases, id: \.self) { action in
                            Label(action.displayName, systemImage: action.systemImage)
                                .tag(action)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section {
                    TextField("Quantity", text: decimalBinding($draft.quantity))
                    TextField("Price", text: decimalBinding($draft.price))
                    TextField("Exchange Rate", text: optionalDecimalBinding($draft.exchangeRate))
                    TextField("Fees", text: optionalDecimalBinding($draft.fees))
                }

                Section {
                    TextField("Note", text: optionalTextBinding($draft.note), axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle(state.transaction == nil ? "New Transaction" : "Edit Transaction")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(normalizedDraft)
                        dismiss()
                    }
                    .disabled(!canSave)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 360)
        #endif
    }

    private var canSave: Bool {
        draft.quantity >= 0 && draft.price >= 0 && (draft.exchangeRate ?? 0) >= 0 && (draft.fees ?? 0) >= 0
    }

    private var normalizedDraft: TradeTransactionDraft {
        var normalized = draft
        normalized.note = draft.note?.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.note?.isEmpty == true {
            normalized.note = nil
        }
        return normalized
    }
}

private extension TradeTransactionAction {
    var displayName: String {
        rawValue.capitalized
    }

    var systemImage: String {
        switch self {
        case .buy:
            "plus.circle.fill"
        case .sell:
            "minus.circle.fill"
        case .add:
            "plus.forwardslash.minus"
        case .trim:
            "scissors"
        case .dividend:
            "banknote.fill"
        case .fee:
            "creditcard.fill"
        }
    }

    var tint: Color {
        switch self {
        case .buy, .add, .dividend:
            .green
        case .sell, .trim:
            .orange
        case .fee:
            .red
        }
    }
}
