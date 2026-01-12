//
//  nameTbc.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 11/01/2026.
//

import Foundation
import SwiftData

@Model
final class Stock {
    var id = UUID()
    var ticker: String
    var entryPrice: Double
    var riskPercentage: Double
    
//    MARK: Loss Data
    var stopLoss: Double
    var shareCount: Double
    
//    MARK: Profit Data
    var targetPrice: Double
    
//    MARK: Account Data
//    var accountUsed: String
//    var balanceAtTrade: Double
//    var amountRisked: Double

    
    @Relationship(inverse: \Account.stocks)
    var account: Account?
    
    init(id: UUID = UUID(),
         ticker: String,
         entryPrice: Double,
         riskPercentage: Double,
         stopLoss: Double,
         shareCount: Double,
         targetPrice: Double,
    ) {
        self.id = id
        self.ticker = ticker
        self.entryPrice = entryPrice
        self.riskPercentage = riskPercentage
        self.stopLoss = stopLoss
        self.shareCount = shareCount
        self.targetPrice = targetPrice
    }
}


