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

    @Bindable var calculation: ForexCalculation
    let isNew: Bool

    var body: some View {
        Form {
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

    private func decimalField(_ label: String, _ value: Binding<Decimal?>) -> some View {
        LabeledContent(label + ":") {
            TextField("", text: optionalDecimalBinding(value))
                .textFieldStyle(CustomTextFieldStyle())
        }
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
}

#Preview {
    AddEditForexCalcView(calculation: ForexCalculation(pair: "EURUSD"), isNew: true)
        .modelContainer(for: ForexCalculation.self, inMemory: true)
}
