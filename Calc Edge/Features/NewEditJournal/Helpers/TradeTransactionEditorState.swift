import Foundation

struct TradeTransactionEditorState: Identifiable {
    let id = UUID()
    let transaction: TradeTransaction?
    let draft: TradeTransactionDraft

    static func new() -> TradeTransactionEditorState {
        TradeTransactionEditorState(
            transaction: nil,
            draft: TradeTransactionDraft()
        )
    }

    static func edit(_ transaction: TradeTransaction) -> TradeTransactionEditorState {
        TradeTransactionEditorState(
            transaction: transaction,
            draft: TradeTransactionDraft(transaction: transaction)
        )
    }
}
