import Foundation

struct TradeTransactionDraft {
    var date: Date = .now
    var action: TradeTransactionAction = .buy
    var quantity: Decimal = 0
    var price: Decimal = 0
    var amount: Decimal?
    var exchangeRate: Decimal?
    var fees: Decimal?
    var note: String?

    init() {}

    init(transaction: TradeTransaction) {
        date = transaction.date
        action = transaction.action
        quantity = transaction.quantity
        price = transaction.price
        amount = transaction.amount
        exchangeRate = transaction.exchangeRate
        fees = transaction.fees
        note = transaction.note
    }
}
