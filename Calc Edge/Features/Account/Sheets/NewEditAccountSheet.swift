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
    
    @State private var text: String = ""
    @State private var currency = "USD"
    @Binding var isNew: Bool
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                TextField("Account Name", text: $account.accountName)
                
                TextField("Account Broker", text: $account.accountBroker)
                
                HStack(spacing: 0) {
                    Text("Currnecy:")
                    
                    Picker("", selection: $currency) {
                        ForEach(currencies, id: \.self) { currency in
                            Text(currency)
                        }
                    }
                    .tint(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 0) {
                    Text("Account Balance: ")
                    
                    TextField("", value: $account.accountSize, formatter: doubleFormatter)
                        .onAppear {
                            text = String(account.accountSize)
                        }
                        .onChange(of: text) {
                            let normalized = text.replacingOccurrences(of: ",", with: ".")
                            if let value = Double(normalized) {
                                account.accountSize = value
                            }
                        }
                }
                    
                #if os(macOS)
                HStack(spacing: 50) {
                    Button(isNew ? "Save" : "Update") {
                        update()
                    }
                    .tint(.green)
                    
                    //                 TODO: Fix Cancel to return original values
                    Button {
                        dismiss()
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                            .tint(.red)
                    }
                }
                #endif
            }
            .navigationTitle("New Account")
            .navigationBarTitleDisplayMode(.inline)
            .padding()
            #if os(iOS)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
//                 TODO: Fix Cancel to return original values
                    Button("Cancel") {
                            dismiss()
                    }
                    .tint(.red)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(isNew ? "Save" : "Update") {
                        update()
                    }
                    .tint(.green)
                    
                    
                }
            }
            #endif
        }
    }
    
    private func update() {
        let account = account
        if isNew {
            modelContext.insert(account)
        }
        dismiss()
    }
}

#Preview {
    NewEditAccountSheet(account: Account(id: UUID(), accountName: "Options Trading", accountBroker: "WeBull", accountSize: 100000, currency: "USD", stocks: [Stock(ticker: "DAL", entryPrice: 47.5, riskPercentage: 1, stopLoss: 45.5, shareCount: 2.8, targetPrice: 55.5, accountUsed: "WeBull", balanceAtTrade: 5000, amountRisked: 100)]), isNew: .constant(false))
}
