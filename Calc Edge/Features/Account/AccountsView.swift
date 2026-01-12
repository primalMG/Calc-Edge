//
//  AccountView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 11/01/2026.
//

import SwiftUI
import SwiftData

struct AccountsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var accounts: [Account]
    @Environment(\.dismiss) private var dismiss
    
    @State private var accountBalance: String = ""
    @State private var presentSheet: Bool = false
    
    @State private var selectedAccount = Account(id: UUID(),
                                                 accountName: "",
                                                 accountSize: 0.0,
                                                 currency: "USD",
                                                 stocks: [])
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack {
                    ForEach(accounts) { account in
                        @Bindable var account = account
                        
                        AccountRow(account: account, onEdit: { accountToEdit in
                            selectedAccount = accountToEdit
                            presentSheet = true
                        })
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button {
                        presentSheet.toggle()
                    } label: {
                        Image(systemName: "plus")
                    }
                    .help("New Account")
                    
                    Button(role: .cancel) {
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark.circle.fill")
                    }

                }
            }
            .sheet(isPresented: $presentSheet) {
                NewEditAccountSheet(account: selectedAccount)
            }
            .navigationTitle("Accounts")
        }
    }
///    TODO: finish creating buttons
    ///    TODO: set up data values to convert data
    ///    TODO: Usual CRUD 
    
    
    private func getAccount() {
        if let account = accounts.first {
            accountBalance =  String(account.accountSize)
        } else {
            accountBalance = ""
        }
    }
    
    private func save() {
        
    }
}

#Preview {
    AccountsView()
        .modelContainer(for: Account.self, inMemory: true)
}
