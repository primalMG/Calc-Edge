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
                Picker("Saved Account", selection: $selectedAccountID) {
                    Text("None")
                        .tag(nil as Account.ID?)

                    ForEach(accounts) { account in
                        Text(account.accountName)
                            .tag(account.id as Account.ID?)
                    }
                }

                if let selectedAccount {
                    LabeledContent("Account Size:") {
                        Text("\(selectedAccount.currency) \(formatAccountSize(selectedAccount.accountSize))")
                    }
                    .foregroundStyle(.secondary)
                } else if accounts.isEmpty {
                    Text("Add an account in Accounts to reuse saved account sizes here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

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

                LabeledContent("Account Currency:") {
                    TextField("", text: $calculation.accountCurrency)
                        .autocorrectionDisabled()
                }
            }

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
                decimalField("Account Balance", $calculation.accountBalance)
                decimalField("Risk Percent", $calculation.riskPercent)
                decimalField("Risk Amount", $calculation.riskAmount)
                decimalField("Entry Price", $calculation.entryPrice)
                decimalField("Stop Loss Price", $calculation.stopLossPrice)
                decimalField("Stop Loss (Pips)", $calculation.stopLossPips)
                decimalField("Quote to Account Rate", $calculation.quoteToAccountRate)
            }
        case .margin:
            Section("Margin Inputs") {
                decimalField("Account Balance", $calculation.accountBalance)
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

    private func format(_ value: Decimal?) -> String {
        guard let value else { return "Waiting for inputs" }
        return NSDecimalNumber(decimal: value).stringValue
    }

    private func save() {
        calculation.pair = calculation.normalizedPair
        calculation.accountCurrency = calculation.accountCurrency.uppercased()

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

        if calculation.accountBalance == nil, !accounts.isEmpty {
            applySelectedAccount()
        }
    }

    private func applySelectedAccount() {
        guard let selectedAccount else { return }

        calculation.accountBalance = Decimal(selectedAccount.accountSize)
        calculation.accountCurrency = selectedAccount.currency.uppercased()
    }

    private func formatAccountSize(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

#Preview {
    AddEditForexCalcView(calculation: ForexCalculation(pair: "EURUSD"), isNew: true)
        .modelContainer(for: [Account.self, ForexCalculation.self], inMemory: true)
}
