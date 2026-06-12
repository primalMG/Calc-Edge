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
                    .tint(Color.gray.gradient)
                    .foregroundStyle(.primary)
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
        let previousSummary = trade.currentPositionSummary
        let wasNew = transaction == nil
        let previousTransactionSummary = transaction.map(transactionSummary(for:))
        let transaction = transaction ?? TradeTransaction(
            date: draft.date,
            action: draft.action,
            quantity: draft.quantity,
            price: draft.price,
            amount: draft.amount,
            exchangeRate: draft.exchangeRate,
            fees: draft.fees,
            note: draft.note
        )

        transaction.date = draft.date
        transaction.action = draft.action
        transaction.quantity = draft.quantity
        transaction.price = draft.price
        transaction.amount = draft.amount
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
            current: trade.currentPositionSummary
        )
    }

    private func remove(_ transaction: TradeTransaction) {
        let previousSummary = trade.currentPositionSummary
        let removedTransactionSummary = transactionSummary(for: transaction)

        if let index = trade.transactions?.firstIndex(where: { $0 === transaction }) {
            trade.transactions?.remove(at: index)
        }

        if transaction.modelContext != nil {
            modelContext.delete(transaction)
        }

        trade.appendValueChangeLog(
            summary: "Deleted \(transaction.action.displayName) transaction",
            detail: removedTransactionSummary,
            previous: previousSummary,
            current: trade.currentPositionSummary
        )
    }

    private func transactionSummary(for transaction: TradeTransaction) -> String {
        var summary: String
        if transaction.action == .dividend, let amount = transaction.amount {
            summary = "\(transaction.action.displayName) \(ValueDisplayFormatter.decimal(amount, fractionDigits: 2))"
        } else {
            summary = "\(transaction.action.displayName) \(ValueDisplayFormatter.decimal(transaction.quantity)) @ \(ValueDisplayFormatter.decimal(transaction.price))"
        }

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
