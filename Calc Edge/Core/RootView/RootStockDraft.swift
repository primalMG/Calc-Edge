extension Stock {
    static var emptyDraft: Stock {
        Stock(
            ticker: "",
            entryPrice: 0.0,
            riskPercentage: 0.0,
            stopLoss: 0.0,
            shareCount: 0.0,
            targetPrice: 0.0,
            accountUsed: "",
            balanceAtTrade: 0.0,
            amountRisked: 0.0
        )
    }
}
