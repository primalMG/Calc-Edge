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
    @State private var toast: ToastConfiguration?
    @State private var didInsertNewStock = false

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

    private var displayRiskAmount: Double? {
        guard selectedAccount != nil, selectedAccountSize > 0, stock.riskPercentage > 0 else {
            return nil
        }

        return calcRiskAmount
    }

    private var displayShareCount: Double? {
        guard let riskAmount = displayRiskAmount, stock.entryPrice > 0 else {
            return nil
        }

        return riskAmount / stock.entryPrice
    }

    private var displayLossDifference: Double? {
        guard stock.entryPrice > 0, stock.stopLoss > 0 else {
            return nil
        }

        return stock.entryPrice - stock.stopLoss
    }

    private var displayLossTotal: Double? {
        guard let lossDifference = displayLossDifference, let shareCount = displayShareCount else {
            return nil
        }

        return lossDifference * shareCount
    }

    private var displayProfitDifference: Double? {
        guard stock.entryPrice > 0, stock.targetPrice > 0 else {
            return nil
        }

        return stock.targetPrice - stock.entryPrice
    }

    private var displayProfitTotal: Double? {
        guard let profitDifference = displayProfitDifference, let shareCount = displayShareCount else {
            return nil
        }

        return profitDifference * shareCount
    }

    private var displayRiskRewardRatio: Double? {
        guard let lossTotal = displayLossTotal,
              let profitTotal = displayProfitTotal,
              lossTotal != 0 else {
            return nil
        }

        return profitTotal / lossTotal
    }

    var body: some View {
        content
            .onAppear(perform: configureInitialAccountSelection)
            .toast($toast)
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
                TextField("", text: doubleBinding($stock.riskPercentage))
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
                TextField("", text: doubleBinding($stock.entryPrice))
                    .textFieldStyle(CustomTextFieldStyle())
            }
        }
    }

    private var riskSetupSection: some View {
        Section("Loss Inputs") {
            LabeledContent("Stop Loss:") {
                TextField("", text: doubleBinding($stock.stopLoss))
                    .textFieldStyle(CustomTextFieldStyle())
            }
        }
    }

    private var targetSetupSection: some View {
        Section("Profit Inputs") {
            LabeledContent("Technical Target:") {
                TextField("", text: doubleBinding($stock.targetPrice))
                    .textFieldStyle(CustomTextFieldStyle())
            }
        }
    }

    private var resultsSection: some View {
        Section("Live Results") {
            resultRow("Amount at Risk", displayRiskAmount)
            resultRow("Shares Bought", displayShareCount)
            resultRow("Loss Difference", displayLossDifference)
            resultRow("Loss Total", displayLossTotal)
            resultRow("Gain Per Share", displayProfitDifference)
            resultRow("Profit", displayProfitTotal)
            resultRow("Risk / Reward", displayRiskRewardRatio)
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

    private func configureInitialAccountSelection() {
        if selectedAccountID == nil {
            selectedAccountID = accounts.first?.id
        }
    }

    private var displayAccountBalance: String {
        guard let selectedAccount else {
            return "No account selected"
        }

        return "\(selectedAccount.currency.uppercased()), \(ValueDisplayFormatter.double(selectedAccount.accountSize))"
    }

    private func save() {
        stock.ticker = stock.ticker
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()

        guard !stock.ticker.isEmpty else {
            toast = ToastConfiguration(
                title: "Ticker Required",
                message: "Enter a ticker before saving this risk calculation.",
                state: .warning
            )
            return
        }

        applyCalculatedStockSnapshot()

        do {
            if isNew {
                if !didInsertNewStock {
                    modelContext.insert(stock)
                    didInsertNewStock = true
                } else {
                    stock.updatedAt = .now
                }
            } else {
                stock.updatedAt = .now
            }

            try modelContext.save()

            toast = ToastConfiguration(
                title: "Calculation Saved",
                message: "Your risk calculation has been saved.",
                state: .success
            )
        } catch {
            toast = ToastConfiguration(
                title: "Save Failed",
                message: error.localizedDescription,
                state: .error,
                duration: 4
            )
        }
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
