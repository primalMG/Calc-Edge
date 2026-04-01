//
//  Stock.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 11/01/2026.
//

import Foundation
import SwiftData

@Model
final class Stock {
    var id = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date?
    var ticker: String = ""
    var entryPrice: Double = 0
    var riskPercentage: Double = 0
    
//    MARK: Loss Data
    var stopLoss: Double = 0
    var shareCount: Double = 0
    
    var lossDiffernce: Double {
        entryPrice - stopLoss
    }
    
    var lossTotal: Double {
        lossDiffernce * shareCount
    }
    
    
//    MARK: Profit Data
    var targetPrice: Double = 0
    var profitDifference: Double {
        targetPrice - entryPrice
    }
    
    var profitTotal: Double {
        profitDifference * shareCount
    }
    
//    MARK: Account Data
    var accountUsed: String = ""
    var balanceAtTrade: Double = 0
    var amountRisked: Double = 0
    
//    MARK: R/R Ratio
    var riskRewardRatio: Double {
        lossTotal == 0 ? 0 : profitTotal / lossTotal
    }

    
    @Relationship(inverse: \Account.stocks)
    var account: Account?
    
    init(id: UUID = UUID(),
         createdAt: Date = Date.now,
         updatedAt: Date? = nil,
         ticker: String,
         entryPrice: Double,
         riskPercentage: Double,
         stopLoss: Double,
         shareCount: Double,
         targetPrice: Double,
         accountUsed: String,
         balanceAtTrade: Double,
         amountRisked: Double,
        ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.ticker = ticker
        self.entryPrice = entryPrice
        self.riskPercentage = riskPercentage
        self.stopLoss = stopLoss
        self.shareCount = shareCount
        self.targetPrice = targetPrice
        self.accountUsed = accountUsed
        self.balanceAtTrade = balanceAtTrade
        self.amountRisked = amountRisked
    }
}
