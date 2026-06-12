import SwiftUI

struct RiskCalcAccountSection: View {
    let accounts: [Account]
    @Binding var selectedAccountID: Account.ID?
    @Binding var riskPercentage: Double
    let displayAccountBalance: String

    var body: some View {
        Section("Account") {
            if accounts.isEmpty {
                Text("Add an account in Accounts to reuse saved account sizes here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                accountPickerRow
            }

            LabeledContent("Balance:") {
                Text(displayAccountBalance)
                    .foregroundStyle(.secondary)
            }

            LabeledContent("Risk Percentage (%):") {
                TextField("", text: doubleBinding($riskPercentage))
                    .textFieldStyle(CustomTextFieldStyle())
            }
        }
    }

    private var accountPickerRow: some View {
        HStack {
            Picker("Accounts:", selection: $selectedAccountID) {
                ForEach(accounts) { account in
                    Text(account.accountName)
                        .tag(account.id as Account.ID?)
                }
            }

            Button {
                print("Open Accounts Sheet")
            } label: {
                Image(systemName: "person.2.fill")
            }
            .help("Open accounts view")
            .frame(width: 20)
        }
    }
}

struct RiskCalcStockDetailsSection: View {
    @Bindable var stock: Stock

    var body: some View {
        Section("Stock Details") {
            LabeledContent("Ticker/Stock:") {
                TextField("", text: $stock.ticker)
                #if os(iOS)
                    .textInputAutocapitalization(.characters)
                #endif
                    .autocorrectionDisabled()
                    .textFieldStyle(CustomTextFieldStyle())
            }

            LabeledContent("Entry Price:") {
                TextField("", text: doubleBinding($stock.entryPrice))
                    .textFieldStyle(CustomTextFieldStyle())
            }
        }
    }
}

struct RiskCalcLossInputsSection: View {
    @Binding var stopLoss: Double

    var body: some View {
        Section("Loss Inputs") {
            LabeledContent("Stop Loss:") {
                TextField("", text: doubleBinding($stopLoss))
                    .textFieldStyle(CustomTextFieldStyle())
            }
        }
    }
}

struct RiskCalcProfitInputsSection: View {
    @Binding var targetPrice: Double

    var body: some View {
        Section("Profit Inputs") {
            LabeledContent("Technical Target:") {
                TextField("", text: doubleBinding($targetPrice))
                    .textFieldStyle(CustomTextFieldStyle())
            }
        }
    }
}

struct RiskCalcLiveResultsSection: View {
    let riskAmount: Double?
    let shareCount: Double?
    let lossDifference: Double?
    let lossTotal: Double?
    let profitDifference: Double?
    let profitTotal: Double?
    let riskRewardRatio: Double?

    var body: some View {
        Section("Live Results") {
            resultRow("Amount at Risk", riskAmount)
            resultRow("Shares Bought", shareCount)
            resultRow("Loss Difference", lossDifference)
            resultRow("Loss Total", lossTotal)
            resultRow("Gain Per Share", profitDifference)
            resultRow("Profit", profitTotal)
            resultRow("Risk / Reward", riskRewardRatio)
        }
    }

    private func resultRow(_ label: String, _ value: Double?) -> some View {
        LabeledContent(label + ":") {
            Text(formatResultValue(value))
                .foregroundStyle(.secondary)
        }
    }

    private func formatResultValue(_ value: Double?) -> String {
        guard let value else {
            return "Waiting for inputs"
        }

        return value.formatted(.number.precision(.fractionLength(2)))
    }
}

struct RiskCalcActionSection: View {
    let onSave: () -> Void
    let onCancel: () -> Void

    @ViewBuilder
    var body: some View {
        #if os(macOS)
        HStack {
            Button("Save", action: onSave)
                .tint(.green)

            Button("Cancel", action: onCancel)
                .tint(.red)
        }
        .padding(.top, 8)
        #endif
    }
}
