//
//  RiskCalcView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 12/01/2026.
//

import SwiftUI
import SwiftData

struct NewEditRiskCalc: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [Account]

    @Bindable var stock: Stock
    let isNew: Bool

    @State private var selectedAccountID: Account.ID?

    private var selectedAccount: Account? {
        accounts.first(where: { $0.id == selectedAccountID }) ?? accounts.first
    }

    private var selectedAccountSize: Double {
        selectedAccount?.accountSize ?? 0
    }

    private var shareCount: Double {
        guard stock.entryPrice != 0 else {
            return 0
        }

        return calcRiskAmount / stock.entryPrice
    }

    private var calcRiskAmount: Double {
        selectedAccountSize * (stock.riskPercentage / 100)
    }

    private var lossDifference: Double {
        stock.entryPrice - stock.stopLoss
    }

    private var lossTotal: Double {
        lossDifference * shareCount
    }

    private var profitDifference: Double {
        stock.targetPrice - stock.entryPrice
    }

    private var profitTotal: Double {
        profitDifference * shareCount
    }

    private var riskRewardRatio: Double {
        lossTotal == 0 ? 0 : profitTotal / lossTotal
    }

    var body: some View {
        content
            .onAppear(perform: configureInitialAccountSelection)
    }

    @ViewBuilder
    private var content: some View {
        #if os(iOS)
        NavigationStack {
            formContent
        }
        #else
        formContent
        #endif
    }

    private var formContent: some View {
        Form {
            accountSection
            stockDetailsSection
            riskSetupSection
            targetSetupSection
            resultsSection
            actionSection
        }
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
                .tint(.red)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .tint(.green)
            }
        }
        #endif
        #if os(macOS)
        .padding()
        .frame(minWidth: 360, idealWidth: 520, maxWidth: 680)
        .frame(minHeight: 600)
        #endif
    }

    @ViewBuilder
    private var accountSection: some View {
        Section("Account") {
            if accounts.isEmpty {
                Text("Add an account in Accounts to reuse saved account sizes here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
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

            LabeledContent("Balance:") {
                Text(displayAccountBalance)
                    .foregroundStyle(.secondary)
            }

            LabeledContent("Risk Percentage (%):") {
                TextField("", value: $stock.riskPercentage, formatter: doubleFormatter)
                    .textFieldStyle(CustomTextFieldStyle())
            }
        }
    }

    private var stockDetailsSection: some View {
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
                TextField("", value: $stock.entryPrice, formatter: doubleFormatter)
                    .textFieldStyle(CustomTextFieldStyle())
            }
        }
    }

    private var riskSetupSection: some View {
        Section("Loss Inputs") {
            LabeledContent("Stop Loss:") {
                TextField("", value: $stock.stopLoss, formatter: doubleFormatter)
                    .textFieldStyle(CustomTextFieldStyle())
            }
        }
    }

    private var targetSetupSection: some View {
        Section("Profit Inputs") {
            LabeledContent("Technical Target:") {
                TextField("", value: $stock.targetPrice, formatter: doubleFormatter)
                    .textFieldStyle(CustomTextFieldStyle())
            }
        }
    }

    private var resultsSection: some View {
        Section("Live Results") {
            resultRow("Amount at Risk", calcRiskAmount)
            resultRow("Shares Bought", shareCount)
            resultRow("Loss Difference", lossDifference)
            resultRow("Loss Total", lossTotal)
            resultRow("Gain Per Share", profitDifference)
            resultRow("Profit", profitTotal)
            resultRow("Risk / Reward", riskRewardRatio)
        }
    }

    @ViewBuilder
    private var actionSection: some View {
        #if os(macOS)
        HStack {
            Button("Save", action: save)
                .tint(.green)

            Button("Cancel") {
                dismiss()
            }
            .tint(.red)
        }
        .padding(.top, 8)
        #endif
    }

    private func resultRow(_ label: String, _ value: Double) -> some View {
        LabeledContent(label + ":") {
            Text(format(value))
                .foregroundStyle(.secondary)
        }
    }

    private func format(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)))
    }

    private func configureInitialAccountSelection() {
        if selectedAccountID == nil {
            selectedAccountID = accounts.first?.id
        }
    }

    private var displayAccountBalance: String {
        guard let selectedAccount else {
            return "No account selected"
        }

        return "\(selectedAccount.currency.uppercased()), \(format(selectedAccount.accountSize))"
    }

    private func save() {
        applyCalculatedStockSnapshot()

        if isNew {
            modelContext.insert(stock)
        } else {
            stock.updatedAt = .now
        }

        dismiss()
    }

    private func applyCalculatedStockSnapshot() {
        stock.shareCount = shareCount
        stock.amountRisked = calcRiskAmount
        stock.account = selectedAccount
        stock.accountUsed = selectedAccount?.accountName ?? ""
        stock.balanceAtTrade = selectedAccount?.accountSize ?? 0
        stock.lossDiffernce = lossDifference
        stock.lossTotal = lossTotal
        stock.profitDifference = profitDifference
        stock.profitTotal = profitTotal
        stock.riskRewardRatio = riskRewardRatio
    }
}

#Preview {
    NewEditRiskCalc(
        stock: Stock(
            ticker: "DAL",
            entryPrice: 47.5,
            riskPercentage: 1,
            stopLoss: 45.5,
            shareCount: 2,
            targetPrice: 55.5,
            accountUsed: "WeBull",
            balanceAtTrade: 5000,
            amountRisked: 100
        ),
        isNew: true
    )
    .modelContainer(for: Account.self, inMemory: true)
}
