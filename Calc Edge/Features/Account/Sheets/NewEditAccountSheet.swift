//
//  NewEditAccountSheet.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 12/01/2026.
//

import SwiftUI
import SwiftData

struct NewEditAccountSheet: View {
    @Bindable var account: Account
    let isNew: Bool
    let onSaved: (SaveOutcome) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var originalValues: AccountDraft?
    @State private var toast: ToastConfiguration?

    enum SaveOutcome {
        case created(accountName: String)
        case updated(accountName: String)
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 15) {
                AccountIdentitySection(account: account)
                AccountCurrencySection(currency: $account.currency)
                AccountBalanceSection(balance: $account.accountSize)

                #if os(macOS)
                AccountSheetActions(
                    saveTitle: isNew ? "Save" : "Update",
                    onSave: save,
                    onCancel: cancel
                )
                #endif
            }
            .navigationTitle(isNew ? "New Account" : "Edit Account")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .padding()
            .onAppear(perform: cacheOriginalValuesIfNeeded)
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        cancel()
                    }
                    .tint(.red)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "Save" : "Update") {
                        save()
                    }
                    .tint(.green)
                }
            }
            #endif
        }
        .toast($toast)
    }

    private func cacheOriginalValuesIfNeeded() {
        guard !isNew, originalValues == nil else {
            return
        }
        originalValues = AccountDraft(account: account)
    }

    private func cancel() {
        if !isNew, let originalValues {
            originalValues.restore(into: account)
        }
        dismiss()
    }

    private func save() {
        normalizeFields()

        guard !account.accountName.isEmpty else {
            toast = ToastConfiguration(
                title: "Name Required",
                message: "Enter an account name before saving.",
                state: .warning
            )
            return
        }

        guard account.currency.count == 3 else {
            toast = ToastConfiguration(
                title: "Currency Required",
                message: "Use a 3-letter currency code (for example USD).",
                state: .warning
            )
            return
        }

        let saveOutcome: SaveOutcome = isNew
            ? .created(accountName: account.accountName)
            : .updated(accountName: account.accountName)

        if isNew {
            modelContext.insert(account)
        }

        do {
            try modelContext.save()
            onSaved(saveOutcome)
            dismiss()
        } catch {
            toast = ToastConfiguration(
                title: "Save Failed",
                message: error.localizedDescription,
                state: .error,
                duration: 4
            )
        }
    }

    private func normalizeFields() {
        account.accountName = account.accountName.trimmingCharacters(in: .whitespacesAndNewlines)
        account.accountBroker = account.accountBroker.trimmingCharacters(in: .whitespacesAndNewlines)
        account.currency = account.currency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }
}

private struct AccountIdentitySection: View {
    @Bindable var account: Account

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Account Name", text: $account.accountName)
            TextField("Account Broker", text: $account.accountBroker)
        }
    }
}

private struct AccountCurrencySection: View {
    @Binding var currency: String

    private var options: [String] {
        let normalizedCurrency = currency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if normalizedCurrency.isEmpty || currencies.contains(normalizedCurrency) {
            return currencies
        }
        return currencies + [normalizedCurrency]
    }

    var body: some View {
        HStack(spacing: 8) {
            Text("Currency:")
            Picker("", selection: $currency) {
                ForEach(options, id: \.self) { code in
                    Text(code).tag(code)
                }
            }
            .labelsHidden()
            .tint(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AccountBalanceSection: View {
    @Binding var balance: Double

    var body: some View {
        HStack(spacing: 8) {
            Text("Account Balance:")
            TextField("", text: doubleBinding($balance))
        }
    }
}

private struct AccountSheetActions: View {
    let saveTitle: String
    let onSave: () -> Void
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 50) {
            Button(saveTitle, action: onSave)
                .tint(.green)

            Button(action: onCancel) {
                Label("Cancel", systemImage: "xmark")
                    .tint(.red)
            }
        }
    }
}

private struct AccountDraft {
    let accountName: String
    let accountBroker: String
    let accountSize: Double
    let currency: String

    init(account: Account) {
        accountName = account.accountName
        accountBroker = account.accountBroker
        accountSize = account.accountSize
        currency = account.currency
    }

    func restore(into account: Account) {
        account.accountName = accountName
        account.accountBroker = accountBroker
        account.accountSize = accountSize
        account.currency = currency
    }
}

#Preview {
    NewEditAccountSheet(
        account: Account(
            id: UUID(),
            accountName: "Options Trading",
            accountBroker: "WeBull",
            accountSize: 100000,
            currency: "USD",
            stocks: [
                Stock(
                    ticker: "DAL",
                    entryPrice: 47.5,
                    riskPercentage: 1,
                    stopLoss: 45.5,
                    shareCount: 2.8,
                    targetPrice: 55.5,
                    accountUsed: "WeBull",
                    balanceAtTrade: 5000,
                    amountRisked: 100
                )
            ]
        ),
        isNew: false,
        onSaved: { _ in }
    )
}
