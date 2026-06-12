import SwiftUI

extension TradeTransactionAction {
    var displayName: String {
        rawValue.capitalized
    }

    var systemImage: String {
        switch self {
        case .buy:
            "plus.circle.fill"
        case .sell:
            "minus.circle.fill"
        case .add:
            "plus.forwardslash.minus"
        case .trim:
            "scissors"
        case .dividend:
            "banknote.fill"
        case .fee:
            "creditcard.fill"
        }
    }

    var tint: Color {
        switch self {
        case .buy, .add, .dividend:
            .green
        case .sell, .trim:
            .orange
        case .fee:
            .red
        }
    }
}
