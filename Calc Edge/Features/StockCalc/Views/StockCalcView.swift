//
//  StockCalc.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 12/01/2026.
//

import SwiftUI
import SwiftData

struct StockCalcView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var toggleAlert: Bool = false
    
    @Bindable var stock: Stock
    
    var riskRewardRatioColor: Color {
        if stock.riskRewardRatio > 1.5 {
            return Color.green
        }
        return Color.red
    }
    
    var body: some View {
        VStack {
            Text("Risk Calculation for \(stock.ticker)")
                .font(.largeTitle)
                
            Divider()
                .padding(.bottom)
            
            Text("Profit: \(stock.profitTotal.formatted())")
                .foregroundStyle(.green.gradient)
                .font(.title)
            
            Text("Loss: \(stock.lossTotal.formatted())")
                .foregroundStyle(.red.gradient)
                .font(.title)
            
            Text("Risk/Reward Ratio: \(stock.riskRewardRatio.formatted())")
                .font(.title3)
                .foregroundStyle(riskRewardRatioColor)
            
            HStack {
                
                VStack {
                    Section {
                        Text("Technical Target: \(stock.stopLoss.formatted())")
                        
                        Text("Profit (per share): \(stock.lossDiffernce.formatted())")
                    } header: {
                        Text("Profit Breakdown:")
                            .padding(.bottom, 5)
                            .font(.headline)
                            .foregroundStyle(.green.gradient)
                    }
                }
                .padding(8)
                .background(.gray.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
                VStack {
                    Section {
                        Text("Stop Loss: \(stock.stopLoss.formatted())")
                        
                        Text("Loss (per share): \(stock.lossDiffernce.formatted())")
                    } header: {
                        Text("Loss Details:")
                            .padding(.bottom, 5)
                            .font(.headline)
                            .foregroundStyle(.red.gradient)
                    }
                }
                .padding(8)
                .background(.gray.secondary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                
            }
            
            VStack {
                Section {
                    HStack(alignment: .top) {
                        VStack {
                            Text("Account Used: \(stock.accountUsed)")
                            
                            Text("Balance At Trade/Calc: \(stock.balanceAtTrade.formatted())")
                            
                            Text("Percentage Of Account Risked: \(stock.riskPercentage.formatted())%")
                        }
                        
                        
                        
                        VStack {
                            Text("Entry Price: \(stock.entryPrice.formatted())")
                            
                            Text("Shares bought: \(stock.shareCount.formatted())")
                        }
                    }
                    
                    
                } header: {
                    Text("Extra Details:")
                }
            }
            .padding(8)
            .background(.gray.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            VStack {
                Section {
                    
                    
                    
                } header: {
                    Text("Stock Details")
                }

            }
        }
        .padding()
        .toolbar {
            ToolbarItemGroup {
                NavigationLink {
                    NewEditRiskCalc(stock: stock)
                } label: {
                    Image(systemName: "pencil")
                }
                .help("Edit Calcuation")
                .keyboardShortcut("E")

                Button {
                    toggleAlert.toggle()
                } label: {
                    Image(systemName: "trash")
                }
                .help("Delete")
                .keyboardShortcut("D")
                .alert("Delete Calculation", isPresented: $toggleAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Yes", role: .destructive) {
                        deleteCalc()
                    }
                } message: {
                    Text("Are you sure you want to do this?")
                }

            }
        }
    }
    
    private func deleteCalc() {
        withAnimation {
            modelContext.delete(stock)
            try? modelContext.save()
        }
        dismiss()
    }
}

#Preview {
    StockCalcView(stock: Stock(ticker: "DAL", entryPrice: 100, riskPercentage: 1, stopLoss: 80, shareCount: 100, targetPrice: 150, accountUsed: "WeBull", balanceAtTrade: 50000, amountRisked: 100))
}
