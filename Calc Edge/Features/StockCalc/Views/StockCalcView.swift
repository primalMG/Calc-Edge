//
//  StockCalc.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 12/01/2026.
//

import SwiftUI

struct StockCalcView: View {
    @Bindable var stock: Stock
    
    var body: some View {
        Text("Hello, World!")
    }
}

#Preview {
    StockCalcView(stock: Stock(ticker: "DAL", entryPrice: 47.5, riskPercentage: 1, stopLoss: 45.5, shareCount: 2.8, targetPrice: 55.5, accountUsed: "WeBull", balanceAtTrade: 5000, amountRisked: 100))
}
