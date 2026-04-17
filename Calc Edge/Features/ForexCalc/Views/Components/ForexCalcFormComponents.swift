import SwiftUI

struct ForexAccountSection: View {
    let accounts: [Account]
    @Binding var selectedAccountID: Account.ID?
    @Bindable var calculation: ForexCalculation
    let formatAccountSize: (Double) -> String

    private var selectedAccount: Account? {
        guard let selectedAccountID else { return nil }
        return accounts.first(where: { $0.id == selectedAccountID })
    }

    var body: some View {
        Section("Account") {
            if accounts.isEmpty {
                Text("Add an account in Accounts to reuse saved account sizes here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !accounts.isEmpty {
                Picker("Saved Account", selection: $selectedAccountID) {
                    Text("Manual Entry")
                        .tag(nil as Account.ID?)
                    ForEach(accounts) { account in
                        Text(account.accountName)
                            .tag(account.id as Account.ID?)
                    }
                }
            }

            if let selectedAccount {
                LabeledContent("Account Currency:") {
                    Text(selectedAccount.currency.uppercased())
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Account Size:") {
                    Text(formatAccountSize(selectedAccount.accountSize))
                        .foregroundStyle(.secondary)
                }
            } else {
                ForexDecimalFieldRow(label: "Account Balance", value: $calculation.accountBalance)
                LabeledContent("Account Currency:") {
                    TextField("", text: $calculation.accountCurrency)
                        .textFieldStyle(CustomTextFieldStyle())
                        .autocorrectionDisabled()
                }
            }
        }
    }
}

struct ForexBasicsSection: View {
    @Bindable var calculation: ForexCalculation
    let pairOptions: [String]
    let canFetchQuoteRate: Bool
    let isFetchingQuoteRate: Bool
    let quoteRateErrorMessage: String?
    let onFetchQuoteRate: () -> Void

    var body: some View {
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
                Picker("", selection: $calculation.pair) {
                    ForEach(pairOptions, id: \.self) { pair in
                        Text(formattedPairLabel(pair))
                            .tag(pair)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            
            quoteRateControls
        }
    }
    
    private var quoteRateControls: some View {
        ForexQuoteRateFetchControls(
            canFetchQuoteRate: canFetchQuoteRate,
            isFetchingQuoteRate: isFetchingQuoteRate,
            quoteRateErrorMessage: quoteRateErrorMessage,
            onFetchQuoteRate: onFetchQuoteRate
        )
    }

    private func formattedPairLabel(_ pair: String) -> String {
        guard pair.count == 6 else { return pair }
        let base = pair.prefix(3)
        let quote = pair.suffix(3)
        return "\(base)/\(quote)"
    }
    
    private struct ForexQuoteRateFetchControls: View {
        let canFetchQuoteRate: Bool
        let isFetchingQuoteRate: Bool
        let quoteRateErrorMessage: String?
        let onFetchQuoteRate: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Button(action: onFetchQuoteRate) {
                    if isFetchingQuoteRate {
                        Label("Fetching latest rate...", systemImage: "hourglass")
                    } else {
                        Label("Fetch Latest Rates", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(!canFetchQuoteRate || isFetchingQuoteRate)

                if let quoteRateErrorMessage {
                    Text(quoteRateErrorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
    }
}

struct ForexCalculatorInputsSection: View {
    @Bindable var calculation: ForexCalculation
    let conversionRateLabel: String
    let marketRateLabel: String
    @Binding var leverageRatioText: String

    var body: some View {
        switch calculation.calculator {
        case .pipValue:
            Section("Pip Value Inputs") {
                ForexDecimalFieldRow(label: "Pip Size", value: $calculation.pipSizeOverride)
                ForexDecimalFieldRow(label: "Lot Size", value: $calculation.lotSize)
                ForexDecimalFieldRow(label: conversionRateLabel, value: $calculation.quoteToAccountRate)
            }
        case .positionSize:
            Section("Position Size Inputs") {
                ForexDecimalFieldRow(label: "Risk Percent", value: $calculation.riskPercent)
                ForexCalculatedRow(label: "Risk Amount", valueText: format(calculation.derivedRiskAmount))
                ForexDecimalFieldRow(label: "Stop Loss (Pips)", value: $calculation.stopLossPips)
                ForexDecimalFieldRow(label: conversionRateLabel, value: $calculation.quoteToAccountRate)
            }
        case .margin:
            Section("Margin Inputs") {
                ForexLeverageRatioField(text: $leverageRatioText)
                ForexDecimalFieldRow(label: "Trade Size (Lots)", value: $calculation.lotSize)
                ForexDecimalFieldRow(label: marketRateLabel, value: $calculation.marketPairRate)
                ForexDecimalFieldRow(label: conversionRateLabel, value: $calculation.quoteToAccountRate)
            }
        case .riskReward:
            Section("Risk/Reward Inputs") {
                ForexDecimalFieldRow(label: "Entry Price", value: $calculation.entryPrice)
                ForexDecimalFieldRow(label: "Stop Loss Price", value: $calculation.stopLossPrice)
                ForexDecimalFieldRow(label: "Take Profit Price", value: $calculation.takeProfitPrice)
                ForexDecimalFieldRow(label: "Stop Loss (Pips)", value: $calculation.stopLossPips)
                ForexDecimalFieldRow(label: "Take Profit (Pips)", value: $calculation.takeProfitPips)
            }
        }
    }

    private func format(_ value: Decimal?) -> String {
        guard let value else { return "Waiting for inputs" }
        return NSDecimalNumber(decimal: value).stringValue
    }
}

struct ForexLiveResultsSection: View {
    @Bindable var calculation: ForexCalculation
    let conversionRateLabel: String
    let marketRateLabel: String

    var body: some View {
        switch calculation.calculator {
        case .pipValue:
            Section("Live Results") {
                ForexResultRow(label: "Pip Size", valueText: format(calculation.pipSize), isMissing: false)
                ForexResultRow(label: marketRateLabel, valueText: formattedMarketRate(calculation.marketPairRate), isMissing: calculation.marketPairRate == nil)
                ForexResultRow(label: conversionRateLabel, valueText: format(calculation.effectiveQuoteToAccountRate), isMissing: calculation.effectiveQuoteToAccountRate == nil)
                ForexResultRow(label: "Pip Value Per Unit", valueText: format(calculation.pipValuePerUnit), isMissing: calculation.pipValuePerUnit == nil)
                ForexResultRow(label: "Total Pip Value", valueText: format(calculation.totalPipValue), isMissing: calculation.totalPipValue == nil)
            }
        case .positionSize:
            Section("Live Results") {
                ForexResultRow(label: "Derived Risk Amount", valueText: format(calculation.derivedRiskAmount), isMissing: calculation.derivedRiskAmount == nil)
                ForexResultRow(label: "Derived Stop Loss (Pips)", valueText: format(calculation.derivedStopLossPips), isMissing: calculation.derivedStopLossPips == nil)
                ForexResultRow(label: marketRateLabel, valueText: formattedMarketRate(calculation.marketPairRate), isMissing: calculation.marketPairRate == nil)
                ForexResultRow(label: conversionRateLabel, valueText: format(calculation.effectiveQuoteToAccountRate), isMissing: calculation.effectiveQuoteToAccountRate == nil)
                ForexResultRow(label: "Pip Value Per Unit", valueText: format(calculation.pipValuePerUnit), isMissing: calculation.pipValuePerUnit == nil)
                ForexResultRow(label: "Position Size Units", valueText: format(calculation.derivedPositionSizeUnits), isMissing: calculation.derivedPositionSizeUnits == nil)
            }
        case .margin:
            Section("Live Results") {
                ForexResultRow(label: marketRateLabel, valueText: formattedMarketRate(calculation.effectiveMarketRate), isMissing: calculation.effectiveMarketRate == nil)
                ForexResultRow(label: conversionRateLabel, valueText: format(calculation.marginQuoteToAccountRate), isMissing: calculation.marginQuoteToAccountRate == nil)
                ForexResultRow(label: "Margin Required", valueText: formatMarginRequired(calculation.derivedMarginRequiredInt), isMissing: calculation.derivedMarginRequiredInt == nil)
            }
        case .riskReward:
            Section("Live Results") {
                ForexResultRow(label: "Derived Stop Loss (Pips)", valueText: format(calculation.derivedStopLossPips), isMissing: calculation.derivedStopLossPips == nil)
                ForexResultRow(label: "Derived Take Profit (Pips)", valueText: format(calculation.derivedTakeProfitPips), isMissing: calculation.derivedTakeProfitPips == nil)
                ForexResultRow(label: "Risk / Reward Ratio", valueText: format(calculation.derivedRiskRewardRatio), isMissing: calculation.derivedRiskRewardRatio == nil)
            }
        }
    }

    private func format(_ value: Decimal?) -> String {
        guard let value else { return "Waiting for inputs" }
        return NSDecimalNumber(decimal: value).stringValue
    }

    private func formattedMarketRate(_ value: Decimal?) -> String {
        guard let value else { return "Waiting for inputs" }
        return value.formatted()
    }

    private func formatMarginRequired(_ value: Int?) -> String {
        guard let value else { return "Waiting for inputs" }
        return String(value)
    }
}

struct ForexFormActionsRow: View {
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack {
            Button("Save", action: onSave)
                .tint(.green)

            Button("Cancel", action: onCancel)
                .tint(.red)
        }
    }
}

private struct ForexDecimalFieldRow: View {
    let label: String
    @Binding var value: Decimal?

    var body: some View {
        LabeledContent(label + ":") {
            TextField("", text: optionalDecimalBinding($value))
                .textFieldStyle(CustomTextFieldStyle())
        }
    }
}

private struct ForexLeverageRatioField: View {
    @Binding var text: String

    var body: some View {
        LabeledContent("Leverage (Ratio):") {
            TextField("", text: $text)
                .textFieldStyle(CustomTextFieldStyle())
        }
    }
}

private struct ForexResultRow: View {
    let label: String
    let valueText: String
    let isMissing: Bool

    var body: some View {
        LabeledContent(label + ":") {
            Text(valueText)
                .foregroundStyle(isMissing ? .secondary : .primary)
        }
    }
}

private struct ForexCalculatedRow: View {
    let label: String
    let valueText: String

    var body: some View {
        LabeledContent(label + ":") {
            Text(valueText)
                .foregroundStyle(.secondary)
        }
    }
}
