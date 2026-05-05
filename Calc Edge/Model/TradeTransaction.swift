import Foundation
import SwiftData

@Model
final class TradeTransaction {
    var id: UUID = UUID()
    var date: Date = Date.now
    var action: TradeTransactionAction = TradeTransactionAction.buy
    var quantity: Decimal = 0
    var price: Decimal = 0
    var exchangeRate: Decimal?
    var fees: Decimal?
    var note: String?

    var trade: Trade?

    init(
        date: Date = .now,
        action: TradeTransactionAction = .buy,
        quantity: Decimal,
        price: Decimal,
        exchangeRate: Decimal? = nil,
        fees: Decimal? = nil,
        note: String? = nil
    ) {
        self.date = date
        self.action = action
        self.quantity = quantity
        self.price = price
        self.exchangeRate = exchangeRate
        self.fees = fees
        self.note = note
    }
}
