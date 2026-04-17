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
    @State private var isFetchingQuoteRate = false
    @State private var quoteRateErrorMessage: String?

    private let ratesClient = OpenExchangeRatesClient()

    var body: some View {
        Form {
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
                    decimalField("Account Balance", $calculation.accountBalance)
                    LabeledContent("Account Currency:") {
                        TextField("", text: $calculation.accountCurrency)
                            .textFieldStyle(CustomTextFieldStyle())
                            .autocorrectionDisabled()
                    }
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

                decimalField("Pip Size", $calculation.pipSizeOverride)
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
        .onChange(of: accountSelectionIDs) { _, _ in
            configureInitialAccountSelection()
        }
        .onChange(of: selectedAccountID) { _, _ in
            applySelectedAccount()
        }
        .onChange(of: calculation.accountBalance) { _, _ in
            calculation.riskAmount = calculation.derivedRiskAmount
        }
        .onChange(of: calculation.accountCurrency) { _, newValue in
            let normalizedCurrency = newValue.uppercased()
            if normalizedCurrency != newValue {
                calculation.accountCurrency = normalizedCurrency
            }
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
                quoteRateFetchControls
                decimalField(conversionRateLabel, $calculation.quoteToAccountRate)
            }
        case .positionSize:
            Section("Position Size Inputs") {
                decimalField("Risk Percent", $calculation.riskPercent)
                decimalField("Entry Price", $calculation.entryPrice)
                decimalField("Stop Loss Price", $calculation.stopLossPrice)
                decimalField("Stop Loss (Pips)", $calculation.stopLossPips)
                quoteRateFetchControls
                decimalField(conversionRateLabel, $calculation.quoteToAccountRate)
            }
        case .margin:
            Section("Margin Inputs") {
                decimalField("Leverage", $calculation.leverage)
                decimalField("Entry Price", $calculation.entryPrice)
                decimalField("Units", $calculation.units)
                decimalField("Lot Size", $calculation.lotSize)
                quoteRateFetchControls
                decimalField(conversionRateLabel, $calculation.quoteToAccountRate)
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
                resultRow("Pip Size", calculation.pipSize)
                resultTextRow(marketRateLabel, formattedMarketRate(calculation.marketPairRate), isMissing: calculation.marketPairRate == nil)
                resultRow(conversionRateLabel, calculation.effectiveQuoteToAccountRate)
                resultRow("Pip Value Per Unit", calculation.pipValuePerUnit)
                resultRow("Total Pip Value", calculation.totalPipValue)
            }
        case .positionSize:
            Section("Live Results") {
                resultRow("Derived Risk Amount", calculation.derivedRiskAmount)
                resultRow("Derived Stop Loss (Pips)", calculation.derivedStopLossPips)
                resultTextRow(marketRateLabel, formattedMarketRate(calculation.marketPairRate), isMissing: calculation.marketPairRate == nil)
                resultRow(conversionRateLabel, calculation.effectiveQuoteToAccountRate)
                resultRow("Pip Value Per Unit", calculation.pipValuePerUnit)
                resultRow("Position Size Units", calculation.derivedPositionSizeUnits)
            }
        case .margin:
            Section("Live Results") {
                resultRow("Derived Units", calculation.derivedUnits)
                resultTextRow(marketRateLabel, formattedMarketRate(calculation.marketPairRate), isMissing: calculation.marketPairRate == nil)
                resultRow(conversionRateLabel, calculation.effectiveQuoteToAccountRate)
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

    private func resultTextRow(_ label: String, _ value: String, isMissing: Bool) -> some View {
        LabeledContent(label + ":") {
            Text(value)
                .foregroundStyle(isMissing ? .secondary : .primary)
        }
    }

    private func calculatedRow(_ label: String, _ value: Decimal?) -> some View {
        LabeledContent(label + ":") {
            Text(format(value))
                .foregroundStyle(.secondary)
        }
    }

    private var quoteRateFetchControls: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                fetchLatestQuoteRate()
            } label: {
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

    private var canFetchQuoteRate: Bool {
        calculation.normalizedPair.count == 6 && calculation.accountCurrency.count == 3
    }

    private var quoteCurrencyCode: String {
        calculation.quoteCurrency ?? "QUOTE"
    }

    private var conversionRateLabel: String {
        "Quote to Account Rate (\(quoteCurrencyCode) -> \(calculation.accountCurrency.uppercased()))"
    }

    private var marketRateLabel: String {
        let base = calculation.baseCurrency ?? "BASE"
        let quote = calculation.quoteCurrency ?? "QUOTE"
        return "Market Rate (\(base)/\(quote))"
    }

    private func format(_ value: Decimal?) -> String {
        guard let value else { return "Waiting for inputs" }
        return NSDecimalNumber(decimal: value).stringValue
    }

    private func formattedMarketRate(_ value: Decimal?) -> String {
        guard let value else { return "Waiting for inputs" }
        return value.formatted()
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

    private func fetchLatestQuoteRate() {
        guard canFetchQuoteRate else {
            quoteRateErrorMessage = "Enter a valid pair (e.g. GBPUSD) and account currency first."
            return
        }

        guard let appID = AppSecrets.openExchangeRatesAppID else {
            quoteRateErrorMessage = "Missing OPEN_EXCHANGE_RATES_APP_ID in app secrets."
            return
        }

        let pair = calculation.normalizedPair
        let accountCurrency = calculation.accountCurrency
        quoteRateErrorMessage = nil
        isFetchingQuoteRate = true

        Task {
            do {
                let snapshot = try await ratesClient.latestRatesSnapshot(
                    for: pair,
                    accountCurrency: accountCurrency,
                    appID: appID
                )

                await MainActor.run {
                    calculation.marketPairRate = snapshot.pairRate
                    calculation.quoteToAccountRate = snapshot.quoteToAccountRate
                    isFetchingQuoteRate = false
                }
            } catch {
                await MainActor.run {
                    quoteRateErrorMessage = error.localizedDescription
                    isFetchingQuoteRate = false
                }
            }
        }
    }

    private var selectedAccount: Account? {
        guard let selectedAccountID else { return nil }
        return accounts.first(where: { $0.id == selectedAccountID })
    }

    private var accountSelectionIDs: [Account.ID] {
        accounts.map(\.id)
    }

    private func configureInitialAccountSelection() {
        if let selectedAccountID,
           !accounts.contains(where: { $0.id == selectedAccountID }) {
            self.selectedAccountID = nil
        }

        if selectedAccountID == nil {
            if let matchingAccountIDForCurrentCalculation {
                selectedAccountID = matchingAccountIDForCurrentCalculation
            } else if calculation.accountBalance == nil {
                selectedAccountID = accounts.first?.id
            }
        }

        if !accounts.isEmpty, selectedAccountID != nil {
            applySelectedAccount()
        }
    }

    private func applySelectedAccount() {
        guard let selectedAccount else { return }

        calculation.accountBalance = Decimal(selectedAccount.accountSize)
        calculation.accountCurrency = selectedAccount.currency.uppercased()
        calculation.riskAmount = calculation.derivedRiskAmount
    }

    private var matchingAccountIDForCurrentCalculation: Account.ID? {
        guard let accountBalance = calculation.accountBalance else { return nil }

        let targetBalance = NSDecimalNumber(decimal: accountBalance).doubleValue
        let targetCurrency = calculation.accountCurrency.uppercased()

        return accounts.first(where: { account in
            abs(account.accountSize - targetBalance) < 0.0001 &&
            account.currency.uppercased() == targetCurrency
        })?.id
    }

    private func formatAccountSize(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

#Preview {
    AddEditForexCalcView(calculation: ForexCalculation(pair: "EURUSD"), isNew: true)
        .modelContainer(for: [Account.self, ForexCalculation.self], inMemory: true)
}
