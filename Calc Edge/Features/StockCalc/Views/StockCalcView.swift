//
//  StockCalc.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 12/01/2026.
//

import SwiftUI

struct StockCalcView: View {
    @Bindable var stock: Stock
    
    var riskRewardRatioColor: Color {
        if stock.riskRewardRatio > 1.5 {
            return Color.green
        }
        return Color.red
    }
    
//    TODO: Build Calcuation View, Should have similar values but a bit more to the point.
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
                Button {
                    
                } label: {
                    Text("Button A")
                }

                Button {
                    
                } label: {
                    Text("Button B")
                }
            }
        }
    }
}

#Preview {
    StockCalcView(stock: Stock(ticker: "DAL", entryPrice: 100, riskPercentage: 1, stopLoss: 80, shareCount: 100, targetPrice: 150, accountUsed: "WeBull", balanceAtTrade: 50000, amountRisked: 100))
}
