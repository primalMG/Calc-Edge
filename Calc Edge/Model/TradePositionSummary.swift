import Foundation

struct TradePositionSummary {
    let currentShareCount: Decimal
    let averagePrice: Decimal?
    let costBasis: Decimal
    let totalFees: Decimal

    static let empty = TradePositionSummary(
        currentShareCount: 0,
        averagePrice: nil,
        costBasis: 0,
        totalFees: 0
    )

    init(
        transactions: [TradeTransaction],
        initialQuantity: Decimal = 0,
        initialAveragePrice: Decimal? = nil
    ) {
        var quantity = initialQuantity
        var costBasis = initialQuantity * (initialAveragePrice ?? 0)
        var totalFees: Decimal = 0

        for transaction in transactions.sorted(by: { $0.date < $1.date }) {
            let fees = transaction.fees ?? 0
            totalFees += fees

            switch transaction.action {
            case .buy, .add:
                quantity += transaction.quantity
                costBasis += (transaction.quantity * transaction.price) + fees
            case .sell, .trim:
                let closingQuantity = min(transaction.quantity, quantity)
                if quantity > 0 {
                    let averageCost = costBasis / quantity
                    costBasis -= averageCost * closingQuantity
                }

                quantity -= closingQuantity

                if quantity <= 0 {
                    quantity = 0
                    costBasis = 0
                }
            case .dividend:
                break
            case .fee:
                if quantity > 0 {
                    costBasis += fees
                }
            }
        }

        self.currentShareCount = quantity
        self.costBasis = costBasis
        self.totalFees = totalFees
        self.averagePrice = quantity > 0 ? costBasis / quantity : nil
    }

    private init(
        currentShareCount: Decimal,
        averagePrice: Decimal?,
        costBasis: Decimal,
        totalFees: Decimal
    ) {
        self.currentShareCount = currentShareCount
        self.averagePrice = averagePrice
        self.costBasis = costBasis
        self.totalFees = totalFees
    }
}

extension Trade {
    var positionSummary: TradePositionSummary {
        TradePositionSummary(transactions: transactions ?? [])
    }

    var currentPositionSummary: TradePositionSummary {
        TradePositionSummary(
            transactions: transactions ?? [],
            initialQuantity: transactionsRepresentStoredShareCount ? 0 : shareCount,
            initialAveragePrice: entryPrice
        )
    }

    var currentShareCount: Decimal {
        currentPositionSummary.currentShareCount
    }

    var currentAveragePrice: Decimal? {
        currentPositionSummary.averagePrice
    }

    var currentSpend: Decimal? {
        let summary = currentPositionSummary
        guard summary.currentShareCount > 0 else {
            return nil
        }

        return summary.costBasis
    }

    var totalProfitLoss: Decimal? {
        guard let entryPrice,
              let comparisonPrice = closedAt == nil ? currentPrice : exitPrice else {
            return nil
        }

        let quantity = currentShareCount > 0 ? currentShareCount : openingTransactionQuantity
        guard quantity > 0 else {
            return nil
        }

        let priceMove: Decimal
        switch direction {
        case .long:
            priceMove = comparisonPrice - entryPrice
        case .short:
            priceMove = entryPrice - comparisonPrice
        }

        return priceMove * quantity
    }

    var dividendTotal: Decimal {
        (transactions ?? []).reduce(0) { total, transaction in
            guard transaction.action == .dividend else {
                return total
            }

            if let amount = transaction.amount {
                return total + amount
            }

            return total + (transaction.quantity * transaction.price)
        }
    }

    var isInitialShareCountLocked: Bool {
        hasPositionTransactions
    }

    var hasPositionTransactions: Bool {
        (transactions ?? []).contains { transaction in
            switch transaction.action {
            case .buy, .add, .sell, .trim:
                return true
            case .dividend, .fee:
                return false
            }
        }
    }

    private var transactionsRepresentStoredShareCount: Bool {
        guard shareCount > 0,
              hasPositionTransactions,
              let entryPrice,
              let averagePrice = positionSummary.averagePrice else {
            return false
        }

        return positionSummary.currentShareCount == shareCount && averagePrice == entryPrice
    }

    private var openingTransactionQuantity: Decimal {
        (transactions ?? []).reduce(0) { total, transaction in
            switch transaction.action {
            case .buy, .add, .sell:
                return total + transaction.quantity
            case .trim, .dividend, .fee:
                return total
            }
        }
    }
}
