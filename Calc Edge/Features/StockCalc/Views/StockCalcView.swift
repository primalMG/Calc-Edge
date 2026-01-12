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
    StockCalcView(stock: Stock(ticker: "DAL", entryPrice: 47.5, riskPercentage: 2, stopLoss: 45.0, shareCount: 5, targetPrice: 55.5))
}
