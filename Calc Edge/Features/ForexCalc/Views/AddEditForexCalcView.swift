//
//  AddEditForexCalcView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 03/02/2026.
//

import SwiftUI
import SwiftData

struct AddEditForexCalcView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [Account]

    @Bindable var calculation: ForexCalculation
    let isNew: Bool
    @State private var selectedAccountID: Account.ID?

    var body: some View {
        Form {
            Section("Account") {
                if accounts.isEmpty {
                    Text("Add an account in Accounts to reuse saved account sizes here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Picker("Saved Account", selection: $selectedAccountID) {
                        ForEach(accounts) { account in
                            Text(account.accountName)
                                .tag(account.id as Account.ID?)
                        }
                    }
                }

                LabeledContent("Account Currency:") {
                    Text(displayAccountCurrency)
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Account Size:") {
                    Text(displayAccountSize)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.top, 10)

            Section("Basics") {
                LabeledContent("Calculator Type:") {
                    Picker("", selection: $calculation.calculator) {
                        ForEach(ForexCalculatorType.allCases, id: \.self) { type in
                            Text(type.displayName)
                                .tag(type)
                        }
                    }
                    .labelsHidden()
                }

                LabeledContent("Pair:") {
                    TextField("", text: $calculation.pair)
                        .autocorrectionDisabled()
                }
            }
            .padding(.top, 10)

            calculatorFields
            liveResultsSection

            HStack {
                Button("Save") {
                    save()
                }
                .tint(.green)

                Button("Cancel") {
                    dismiss()
                }
                .tint(.red)
            }
            .padding(.top, 8)
        }
        .padding()
        .frame(minWidth: 520, idealWidth: 620, maxWidth: 800)
        .frame(minHeight: 520)
        .onAppear(perform: configureInitialAccountSelection)
        .onChange(of: selectedAccountID) { _, _ in
            applySelectedAccount()
        }
        .onChange(of: calculation.riskPercent) { _, _ in
            calculation.riskAmount = calculation.derivedRiskAmount
        }
    }

    @ViewBuilder
    private var calculatorFields: some View {
        switch calculation.calculator {
        case .pipValue:
            Section("Pip Value Inputs") {
                decimalField("Lot Size", $calculation.lotSize)
                decimalField("Units", $calculation.units)
                decimalField("Pip Size Override", $calculation.pipSizeOverride)
                decimalField("Quote to Account Rate", $calculation.quoteToAccountRate)
            }
        case .positionSize:
            Section("Position Size Inputs") {
                decimalField("Risk Percent", $calculation.riskPercent)
                calculatedRow("Risk Amount", calculation.derivedRiskAmount)
                decimalField("Entry Price", $calculation.entryPrice)
                decimalField("Stop Loss Price", $calculation.stopLossPrice)
                decimalField("Stop Loss (Pips)", $calculation.stopLossPips)
                decimalField("Quote to Account Rate", $calculation.quoteToAccountRate)
            }
        case .margin:
            Section("Margin Inputs") {
                decimalField("Leverage", $calculation.leverage)
                decimalField("Entry Price", $calculation.entryPrice)
                decimalField("Units", $calculation.units)
                decimalField("Lot Size", $calculation.lotSize)
                decimalField("Quote to Account Rate", $calculation.quoteToAccountRate)
            }
        case .riskReward:
            Section("Risk/Reward Inputs") {
                decimalField("Entry Price", $calculation.entryPrice)
                decimalField("Stop Loss Price", $calculation.stopLossPrice)
                decimalField("Take Profit Price", $calculation.takeProfitPrice)
                decimalField("Stop Loss (Pips)", $calculation.stopLossPips)
                decimalField("Take Profit (Pips)", $calculation.takeProfitPips)
            }
        }
    }

    @ViewBuilder
    private var liveResultsSection: some View {
        switch calculation.calculator {
        case .pipValue:
            Section("Live Results") {
                resultRow("Derived Units", calculation.derivedUnits)
                resultRow("Pip Size", calculation.pipSize)
                resultRow("Quote to Account Rate", calculation.effectiveQuoteToAccountRate)
                resultRow("Pip Value Per Unit", calculation.pipValuePerUnit)
                resultRow("Total Pip Value", calculation.totalPipValue)
            }
        case .positionSize:
            Section("Live Results") {
                resultRow("Derived Risk Amount", calculation.derivedRiskAmount)
                resultRow("Derived Stop Loss (Pips)", calculation.derivedStopLossPips)
                resultRow("Pip Value Per Unit", calculation.pipValuePerUnit)
                resultRow("Position Size Units", calculation.derivedPositionSizeUnits)
            }
        case .margin:
            Section("Live Results") {
                resultRow("Derived Units", calculation.derivedUnits)
                resultRow("Margin Required", calculation.derivedMarginRequired)
            }
        case .riskReward:
            Section("Live Results") {
                resultRow("Derived Stop Loss (Pips)", calculation.derivedStopLossPips)
                resultRow("Derived Take Profit (Pips)", calculation.derivedTakeProfitPips)
                resultRow("Risk / Reward Ratio", calculation.derivedRiskRewardRatio)
            }
        }
    }

    private func decimalField(_ label: String, _ value: Binding<Decimal?>) -> some View {
        LabeledContent(label + ":") {
            TextField("", text: optionalDecimalBinding(value))
                .textFieldStyle(CustomTextFieldStyle())
        }
    }

    private func resultRow(_ label: String, _ value: Decimal?) -> some View {
        LabeledContent(label + ":") {
            Text(format(value))
                .foregroundStyle(value == nil ? .secondary : .primary)
        }
    }

    private func calculatedRow(_ label: String, _ value: Decimal?) -> some View {
        LabeledContent(label + ":") {
            Text(format(value))
                .foregroundStyle(.secondary)
        }
    }

    private func format(_ value: Decimal?) -> String {
        guard let value else { return "Waiting for inputs" }
        return NSDecimalNumber(decimal: value).stringValue
    }

    private func save() {
        calculation.pair = calculation.normalizedPair
        if let selectedAccount {
            calculation.accountBalance = Decimal(selectedAccount.accountSize)
            calculation.accountCurrency = selectedAccount.currency.uppercased()
        }
        calculation.riskAmount = calculation.derivedRiskAmount

        if isNew {
            modelContext.insert(calculation)
        } else {
            calculation.updatedAt = .now
        }

        dismiss()
    }

    private var selectedAccount: Account? {
        guard let selectedAccountID else { return nil }
        return accounts.first(where: { $0.id == selectedAccountID })
    }

    private func configureInitialAccountSelection() {
        if selectedAccountID == nil {
            selectedAccountID = accounts.first?.id
        }

        if !accounts.isEmpty {
            applySelectedAccount()
        }
    }

    private func applySelectedAccount() {
        guard let selectedAccount else { return }

        calculation.accountBalance = Decimal(selectedAccount.accountSize)
        calculation.accountCurrency = selectedAccount.currency.uppercased()
        calculation.riskAmount = calculation.derivedRiskAmount
    }

    private func formatAccountSize(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private var displayAccountCurrency: String {
        if let selectedAccount {
            return selectedAccount.currency.uppercased()
        }

        if !calculation.accountCurrency.isEmpty {
            return calculation.accountCurrency.uppercased()
        }

        return "No account selected"
    }

    private var displayAccountSize: String {
        if let selectedAccount {
            return formatAccountSize(selectedAccount.accountSize)
        }

        if let accountBalance = calculation.accountBalance {
            return NSDecimalNumber(decimal: accountBalance).stringValue
        }

        return "No account selected"
    }
}

#Preview {
    AddEditForexCalcView(calculation: ForexCalculation(pair: "EURUSD"), isNew: true)
        .modelContainer(for: [Account.self, ForexCalculation.self], inMemory: true)
}
