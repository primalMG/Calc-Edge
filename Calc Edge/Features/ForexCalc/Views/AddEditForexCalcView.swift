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

    private let usdBaseCurrencies: [String] = [
        "AED", "ARS", "AUD", "BHD", "BRL", "CAD", "CHF", "CLP", "CNY", "COP",
        "CZK", "DKK", "EUR", "GBP", "HKD", "HUF", "IDR", "ILS", "INR", "JPY",
        "KRW", "KWD", "MXN", "MYR", "NOK", "NZD", "PHP", "PKR", "PLN", "QAR",
        "RUB", "SAR", "SEK", "SGD", "THB", "TRY", "TWD", "ZAR"
    ]

    private let ratesClient = OpenExchangeRatesClient()

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

    private var usdPairOptions: [String] {
        var pairs = usdBaseCurrencies.map { "\($0)USD" }
        let currentPair = normalizedPair(calculation.pair)
        if currentPair.count == 6, !pairs.contains(currentPair) {
            pairs.append(currentPair)
        }
        return pairs
    }

    private var autoFetchPairs: Set<String> {
        Set(usdBaseCurrencies.map { "\($0)USD" })
    }

    private var selectedAccount: Account? {
        guard let selectedAccountID else { return nil }
        return accounts.first(where: { $0.id == selectedAccountID })
    }

    private var accountSelectionIDs: [Account.ID] {
        accounts.map(\.id)
    }

    private var leverageBinding: Binding<String> {
        Binding(
            get: {
                guard let leverage = calculation.leverage else { return "" }
                return "1:\(leverage)"
            },
            set: { newValue in
                calculation.leverage = parseLeverageRatio(newValue)
            }
        )
    }

    var body: some View {
        Form {
            ForexAccountSection(
                accounts: accounts,
                selectedAccountID: $selectedAccountID,
                calculation: calculation,
                formatAccountSize: formatAccountSize
            )
            .padding(.top, 10)

            ForexBasicsSection(calculation: calculation,
                               pairOptions: usdPairOptions,
                               canFetchQuoteRate: canFetchQuoteRate,
                               isFetchingQuoteRate: isFetchingQuoteRate,
                               quoteRateErrorMessage: quoteRateErrorMessage,
                               onFetchQuoteRate: fetchLatestQuoteRate
            )
                .padding(.top, 10)

            ForexCalculatorInputsSection(
                calculation: calculation,
                conversionRateLabel: conversionRateLabel,
                marketRateLabel: marketRateLabel,
                leverageRatioText: leverageBinding
            )

            ForexLiveResultsSection(
                calculation: calculation,
                conversionRateLabel: conversionRateLabel,
                marketRateLabel: marketRateLabel
            )

            ForexFormActionsRow(
                onSave: save,
                onCancel: { dismiss() }
            )
            .padding(.top, 8)
        }
        #if os(macOS)
        .padding()
        .frame(minWidth: 520, idealWidth: 620, maxWidth: 800)
        .frame(minHeight: 520)
        #endif
        .onAppear {
            configureInitialPairSelection()
            configureInitialAccountSelection()
        }
        .onChange(of: accountSelectionIDs) { _, _ in
            configureInitialAccountSelection()
        }
        .onChange(of: selectedAccountID) { _, _ in
            applySelectedAccount()
        }
        .onChange(of: calculation.pair) { oldValue, newValue in
            guard !oldValue.isEmpty, oldValue != newValue else { return }
            let normalized = normalizedPair(newValue)
            if autoFetchPairs.contains(normalized), canFetchQuoteRate {
                fetchLatestQuoteRate()
            }
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

    private func parseLeverageRatio(_ value: String) -> Decimal? {
        let cleaned = value.replacingOccurrences(of: " ", with: "")
        guard !cleaned.isEmpty else { return nil }

        let parts = cleaned.split(separator: ":")
        if parts.count == 2,
           let left = Decimal(string: String(parts[0])),
           let right = Decimal(string: String(parts[1])),
           left > 0, right > 0 {
            return right / left
        }

        if let decimal = Decimal(string: cleaned), decimal > 0 {
            return decimal
        }

        return calculation.leverage
    }

    private func formatAccountSize(_ value: Double) -> String {
        String(format: "%.2f", value)
    }

    private func configureInitialPairSelection() {
        let normalized = normalizedPair(calculation.pair)
        if normalized != calculation.pair {
            calculation.pair = normalized
        }

        if calculation.pair.isEmpty, let firstPair = usdPairOptions.first {
            calculation.pair = firstPair
        }
    }

    private func normalizedPair(_ value: String) -> String {
        value
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "/", with: "")
    }
}

#Preview {
    AddEditForexCalcView(calculation: ForexCalculation(pair: "EURUSD"), isNew: true)
        .modelContainer(for: [Account.self, ForexCalculation.self], inMemory: true)
}
