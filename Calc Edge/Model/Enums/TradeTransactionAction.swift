import Foundation

enum TradeTransactionAction: String, Codable, CaseIterable {
    case buy
    case sell
    case add
    case trim
    case dividend
    case fee
}
