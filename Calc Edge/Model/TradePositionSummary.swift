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

    init(transactions: [TradeTransaction]) {
        var quantity: Decimal = 0
        var costBasis: Decimal = 0
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
}
