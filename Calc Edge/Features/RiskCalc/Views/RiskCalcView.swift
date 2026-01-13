//
//  RiskCalcView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 12/01/2026.
//

import SwiftUI

struct RiskCalcView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var stock: Stock
    @Binding var accounts: [Account]
    
    @State private var selectedAccountID: Account.ID?

    private var selectedAccount: Account {
        accounts.first(where: { $0.id == selectedAccountID })
        ?? accounts.first
        ?? Account(id: UUID(), accountName: "", accountSize: 0, currency: "")
    }
    

    private var calcShares: Double {
        stock.riskPercentage / 100 * selectedAccount.accountSize / stock.entryPrice
    }
    
    var body: some View {
        HStack {
            Form {
                Section {
                    Picker("Accounts:", selection: $selectedAccountID) {
                        ForEach(accounts) { account in
                            Text(account.accountName)
                                .tag(account.id as Account.ID?)
                        }
                    }
                    
                    HStack {
                        LabeledContent("Balance:") {
                            Text(selectedAccount.currency + ", ")
                            
                            Text(String(format: "%.2f", selectedAccount.accountSize))
                        }
                    }
                    
                    TextField("Risk Percentage (%):", value: $stock.riskPercentage, formatter: doubleFormatter)
                        .onChange(of: stock.riskPercentage) { _, _ in
                            stock.shareCount = calcShares
                        }
                    
                    LabeledContent("Ammount at Risk:") {
                        Text(String(format: "%.2f", stock.amountRisked))
                    }
                } header: {
                    Text("Account")
                }
                
                Section {
                    
                    TextField("Ticker/Stock:", text: $stock.ticker)
                    
                    LabeledContent("# Shares Bought:") {
                        Text(String(format: "%.2f", stock.shareCount))
                    }
                    
                    TextField("Entry Price:", value: $stock.entryPrice, formatter: doubleFormatter)
                    
                } header: {
                    Text("Stock Details")
                        .padding(.top, 15)
                }
                
                Section {

                    TextField("Stop Loss:", value: $stock.stopLoss, formatter: doubleFormatter)
                    
                    LabeledContent("Loss difference:") {
                        Text(String(format: "%.2f", stock.lossDiffernce))
                    }
                    
                    LabeledContent("Loss Total:") {
                        Text(String(format: "%.2f", stock.lossTotal))
                    }
                    
                    
                } header: {
                    Text("Loss Details")
                        .padding(.top, 15)
                }
                
                Section {
                    TextField("Technical Target:", value: $stock.targetPrice, formatter: doubleFormatter)
                    
                    LabeledContent("Gain Per Share:") {
                        Text(String(format: "%.2f", stock.profitDifference))
                    }
                    
                    LabeledContent("Profit:") {
                        Text(String(format: "%.2f", stock.profitTotal))
                    }
                    
                } header: {
                    Text("Profit Details")
                        .padding(.top, 15)
                }

                HStack {
                    Button {
                        save()
                    } label: {
                        Text("Save")
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
            }
            .onAppear {
                if selectedAccountID == nil {
                    selectedAccountID = accounts.first?.id
                }
            }
            .padding()
            .frame(idealWidth: 400, maxWidth: 500)
        }
        .padding()
        .frame(minHeight: 600)
    }
    
    private func save() {
        
    }
}

#Preview {
    RiskCalcView(stock: Stock(ticker: "DAL", entryPrice: 47.5, riskPercentage: 1, stopLoss: 45.5, shareCount: 2, targetPrice: 55.5, accountUsed: "WeBull", balanceAtTrade: 5000, amountRisked: 100), accounts: .constant([Account(id: UUID(), accountName: "WeBull", accountSize: 5000, currency: "USD"), Account(id: UUID(), accountName: "Robinhood", accountSize: 10000, currency: "USD")]))
}
