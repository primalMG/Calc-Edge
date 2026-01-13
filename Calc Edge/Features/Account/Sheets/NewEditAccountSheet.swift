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
    @State private var isNew: Bool = false
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack {
            Form {
                
                TextField("Account Name:", text: $account.accountName)
                
                Picker("Currency:", selection: $currency) {
                    ForEach(currencies, id: \.self) { currency in
                        Text(currency)
                    }
                }
                
//              TODO: Fix behaviour of textfield
                TextField("Account Size:", value: $account.accountSize, formatter: doubleFormatter)
                    .onAppear {
                        text = String(account.accountSize)
                    }
                    .onChange(of: text) {
                        let normalized = text.replacingOccurrences(of: ",", with: ".")
                        if let value = Double(normalized) {
                            account.accountSize = value
                        }
                    }
                
                HStack {
                    Button(isNew ? "Save" : "Update") {
                        update()
                    }
                    .tint(.green)
                    
//                 TODO: Fix Cancel to return original values
                    Button {
                        dismiss()
                    } label: {
                        Label("Cancel", systemImage: "xmark")
                    }
                    .tint(.red)
                }

            }
        }
        .padding()
        .onAppear {
            if account.accountName.isEmpty {
                isNew = true
            }
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
    NewEditAccountSheet(account: Account(id: UUID(), accountName: "Webull", accountSize: 100000, currency: "USD", stocks: [Stock(ticker: "DAL", entryPrice: 47.5, riskPercentage: 1, stopLoss: 45.5, shareCount: 2.8, targetPrice: 55.5, accountUsed: "WeBull", balanceAtTrade: 5000, amountRisked: 100)]))
}
