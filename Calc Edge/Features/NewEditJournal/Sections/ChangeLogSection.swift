import SwiftUI

struct ChangeLogSection: View {
    @Bindable var trade: Trade
    var includesContainer = true

    private var changeLogs: [TradeValueChangeLog] {
        (trade.valueChangeLogs ?? []).sorted { $0.changedAt > $1.changedAt }
    }

    var body: some View {
        if includesContainer {
            JournalSectionContainer("Change Log") {
                changeLogContent
            }
        } else {
            changeLogContent
        }
    }

    @ViewBuilder
    private var changeLogContent: some View {
        if changeLogs.isEmpty {
            Text("No changes recorded yet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(changeLogs) { log in
                    TradeValueChangeLogRow(log: log)
                }
            }
        }
    }
}

private struct TradeValueChangeLogRow: View {
    let log: TradeValueChangeLog

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(log.summary)
                    .font(.subheadline.weight(.semibold))

                Text(log.changedAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(log.changedAt, style: .time)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let detail = log.detail, !detail.isEmpty {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(logValueChange)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var logValueChange: String {
        let previousAverage = ValueDisplayFormatter.decimal(log.previousAveragePrice, placeholder: "none")
        let newAverage = ValueDisplayFormatter.decimal(log.newAveragePrice, placeholder: "none")

        return "Shares \(ValueDisplayFormatter.decimal(log.previousShareCount)) -> \(ValueDisplayFormatter.decimal(log.newShareCount)) | Avg \(previousAverage) -> \(newAverage)"
    }
}
