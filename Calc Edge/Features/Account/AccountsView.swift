//
//  AccountView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 11/01/2026.
//

import SwiftUI
import SwiftData

struct AccountsView: View {
    @Query private var accounts: [Account]
    @Environment(\.dismiss) private var dismiss

    @State private var presentSheet = false
    @State private var isNew = true
    @State private var toast: ToastConfiguration?
    @State private var selectedAccount = Account(
        id: UUID(),
        accountName: "",
        accountBroker: "",
        accountSize: 0.0,
        currency: "USD",
        stocks: []
    )

    var body: some View {
        NavigationStack {
            AccountsList(
                accounts: accounts,
                onEdit: presentEditAccountSheet,
                onDelete: handleAccountDeleted
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .automatic) {
                    Button(action: presentNewAccountSheet) {
                        Label("New Account", systemImage: "plus")
                    }
                    .help("New Account")
                }
            }
            .sheet(isPresented: $presentSheet) {
                NewEditAccountSheet(
                    account: selectedAccount,
                    isNew: isNew,
                    onSaved: handleSaveOutcome
                )
                    .presentationDetents([.fraction(0.3)])
            }
            .toast($toast)
            .navigationTitle("Accounts")
        }
    }

    private func presentNewAccountSheet() {
        selectedAccount = Account(
            id: UUID(),
            accountName: "",
            accountBroker: "",
            accountSize: 0.0,
            currency: "USD",
            stocks: []
        )
        isNew = true
        presentSheet = true
    }

    private func presentEditAccountSheet(_ account: Account) {
        selectedAccount = account
        isNew = false
        presentSheet = true
    }

    private func handleSaveOutcome(_ outcome: NewEditAccountSheet.SaveOutcome) {
        switch outcome {
        case .created(let accountName):
            toast = ToastConfiguration(
                title: "Account Created",
                message: "\(accountName) was added successfully.",
                state: .success
            )
        case .updated(let accountName):
            toast = ToastConfiguration(
                title: "Account Updated",
                message: "\(accountName) was updated successfully.",
                state: .success
            )
        }
    }

    private func handleAccountDeleted(_ accountName: String) {
        toast = ToastConfiguration(
            title: "Account Deleted",
            message: "\(accountName) was deleted.",
            state: .info
        )
    }
}

private struct AccountsList: View {
    let accounts: [Account]
    let onEdit: (Account) -> Void
    let onDelete: (String) -> Void

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(accounts) { account in
                    @Bindable var account = account
                    AccountRow(
                        account: account,
                        onEdit: onEdit,
                        onDelete: onDelete
                    )
                }
            }
        }
    }
}

#Preview {
    AccountsView()
        .modelContainer(for: Account.self, inMemory: true)
}
