//
//  RiskCalcView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 12/01/2026.
//

import SwiftUI
import SwiftData

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
                    HStack {
                        Picker("Accounts:", selection: $selectedAccountID) {
                            ForEach(accounts) { account in
                                Text(account.accountName)
                                    .tag(account.id as Account.ID?)
                            }
                        }
                        
                        Button {
                            print("Open Accounts Sheet")
                        } label: {
                            Image(systemName: "person.2.fill")
                        }
                        .help("Open accounts view")
                        .frame(width: 20)

                    }
                    
                    HStack {
                        LabeledContent("Balance:") {
                            Text(selectedAccount.currency + ", ")
                            
                            Text(String(format: "%.2f", selectedAccount.accountSize))
                        }
                    }
                    
                    LabeledContent("Risk Percentage (%):") {
                        TextField("", value: $stock.riskPercentage, formatter: doubleFormatter)
                            .textFieldStyle(CustomTextFieldStyle())
                            .onChange(of: stock.riskPercentage) { _, _ in
                                stock.shareCount = calcShares
                            }
                    }
                   
                    LabeledContent("Ammount at Risk:") {
                        Text(String(format: "%.2f", stock.amountRisked))
                    }
                    
                } header: {
                    Text("Account")
                }
                
                Section {
                    
                    LabeledContent("Ticker/Stock:") {
                        TextField("", text: $stock.ticker)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                    LabeledContent("# Shares Bought:") {
                        Text(String(format: "%.2f", stock.shareCount))
                    }
                    
                    LabeledContent("Entry Price:") {
                        TextField("", value: $stock.entryPrice, formatter: doubleFormatter)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
                } header: {
                    Text("Stock Details")
                        .padding(.top, 15)
                }
                
                Section {

                    LabeledContent("Stop Loss:") {
                        TextField("", value: $stock.stopLoss, formatter: doubleFormatter)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
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
                    
                    LabeledContent("Technical Target:") {
                        TextField("", value: $stock.targetPrice, formatter: doubleFormatter)
                            .textFieldStyle(CustomTextFieldStyle())
                    }
                    
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

                HStack() {
                    Button {
                        save()
                    } label: {
                        Text("Save")
                    }
                    .tint(.green)
                    
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                    .tint(.red)
                }
                .padding(.top, 10)
            }
            .onAppear {
                if selectedAccountID == nil {
                    selectedAccountID = accounts.first?.id
                }
            }
            .padding()
            .frame(minWidth: 200, idealWidth: 200, maxWidth: 500)
        }
        .padding()
        .frame(minHeight: 600)
    }
    
    private func save() {
        modelContext.insert(stock)
    }
}

#Preview {
    RiskCalcView(stock: Stock(ticker: "DAL", entryPrice: 47.5, riskPercentage: 1, stopLoss: 45.5, shareCount: 2, targetPrice: 55.5, accountUsed: "WeBull", balanceAtTrade: 5000, amountRisked: 100), accounts: .constant([Account(id: UUID(), accountName: "WeBull", accountSize: 5000, currency: "USD"), Account(id: UUID(), accountName: "Robinhood", accountSize: 10000, currency: "USD")]))
}
