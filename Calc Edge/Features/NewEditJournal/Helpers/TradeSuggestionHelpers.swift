import Foundation
import SwiftData

enum TradeSuggestionField: String, CaseIterable {
    case strategyName
    case setupType
    case timeframe
    case catalyst
    case reviewMistakeType
    case reviewPostTradeNotes
    case reviewWhatWentRight
    case reviewWhatWentWrong
    case reviewOneImprovement
    case reviewRuleCreatedOrUpdated
    case marketIndexTrend
    case marketSectorStrength
    case marketNewsDuringTrade
    case marketTimeOfDayTag
}

extension ModelContext {
    func upsertTradeSuggestion(field: TradeSuggestionField, value: String) {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedValue.isEmpty else {
            return
        }

        let uniqueKey = TradeFieldSuggestion.makeUniqueKey(
            field: field.rawValue,
            value: trimmedValue
        )
        let descriptor = FetchDescriptor<TradeFieldSuggestion>(
            predicate: #Predicate { suggestion in
                suggestion.uniqueKey == uniqueKey
            }
        )

        if let existingSuggestion = try? fetch(descriptor).first {
            existingSuggestion.value = trimmedValue
            existingSuggestion.useCount += 1
            existingSuggestion.lastUsedAt = .now
        } else {
            let suggestion = TradeFieldSuggestion(
                field: field.rawValue,
                value: trimmedValue
            )
            insert(suggestion)
        }
    }
}
