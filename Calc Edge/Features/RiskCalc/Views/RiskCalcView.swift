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
    
    private var amountAtRisk: Double {
        stock.riskPercentage / 100 * selectedAccount.accountSize
    }
    
    private var calcLoss: Double {
        stock.stopLoss * stock.shareCount
    }
    
    private var calcShares: Double {
        amountAtRisk / stock.entryPrice
    }
    
    private var calcLossDiffernce: Double {
        stock.entryPrice - stock.stopLoss
    }
    
    private var calcProfitDiffernce: Double {
        stock.targetPrice - stock.entryPrice
    }
    
    private var calcProfit: Double {
        calcShares * calcProfitDiffernce
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
                            
                            Text(selectedAccount.accountSize.formatted())
                        }
                    }
                    
                    TextField("Risk Percentage (%):", value: $stock.riskPercentage, formatter: doubleFormatter)
                        .onChange(of: stock.riskPercentage) { _, _ in
                            stock.shareCount = calcShares
                        }
                    
                    LabeledContent("Ammount at Risk:") {
                        Text("\(amountAtRisk.formatted())")
                    }
                } header: {
                    Text("Account")
                }
                
                Section {
                    
                    TextField("Ticker/Stock:", text: $stock.ticker)
                    
                    LabeledContent("# Shares Bought:") {
                        Text("\(calcShares.formatted())")
                    }
                    
                    TextField("Entry Price:", value: $stock.entryPrice, formatter: doubleFormatter)
                    
                } header: {
                    Text("Stock Details")
                        .padding(.top, 15)
                }
                
                Section {

                    TextField("Stop Loss:", value: $stock.stopLoss, formatter: doubleFormatter)
                    
                    LabeledContent("Loss difference:") {
                        Text("\(calcLossDiffernce.formatted())")
                    }
                    
                    LabeledContent("Loss Total:") {
                        Text("\(calcLoss.formatted())")
                    }
                    
                    
                } header: {
                    Text("Loss Details")
                        .padding(.top, 15)
                }
                
                Section {
                    TextField("Technical Target:", value: $stock.targetPrice, formatter: doubleFormatter)
                    
                    LabeledContent("Gain Per Share:") {
                        Text("\(calcProfitDiffernce.formatted())")
                    }
                    
                    LabeledContent("Profit:") {
                        Text("\(calcProfit.formatted())")
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
        }
        .padding()
        .frame(minHeight: 600)
    }
    
    private func save() {
        
    }
}

#Preview {
    RiskCalcView(stock: Stock(ticker: "DAL", entryPrice: 47.5, riskPercentage: 2, stopLoss: 45.0, shareCount: 5, targetPrice: 55.5), accounts: .constant([Account(id: UUID(), accountName: "WeBull", accountSize: 5000, currency: "USD"), Account(id: UUID(), accountName: "Robinhood", accountSize: 10000, currency: "USD")]))
}
