import SwiftUI

struct TradeTransactionRow: View {
    @Bindable var transaction: TradeTransaction
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: transaction.action.systemImage)
                .font(.headline)
                .foregroundStyle(transaction.action.tint)
                .frame(width: 24, height: 24)

            TradeTransactionRowContent(transaction: transaction)

            Spacer(minLength: 8)

            TradeTransactionRowActions(onEdit: onEdit, onDelete: onDelete)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private struct TradeTransactionRowContent: View {
    @Bindable var transaction: TradeTransaction

    var body: some View {
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
    }

    private var transactionDetail: String {
        let base: String
        if transaction.action == .dividend, let amount = transaction.amount {
            base = "Amount \(ValueDisplayFormatter.decimal(amount, fractionDigits: 2))"
        } else {
            let quantity = ValueDisplayFormatter.decimal(transaction.quantity)
            let price = ValueDisplayFormatter.decimal(transaction.price)
            base = "\(quantity) @ \(price)"
        }

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

private struct TradeTransactionRowActions: View {
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Edit transaction")

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .accessibilityLabel("Delete transaction")
        }
    }
}
