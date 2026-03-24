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

    var title: String {
        switch self {
        case .strategyName:
            "Strategy Name"
        case .setupType:
            "Setup Type"
        case .timeframe:
            "Timeframe"
        case .catalyst:
            "Catalyst"
        case .reviewMistakeType:
            "Review Mistake Type"
        case .reviewPostTradeNotes:
            "Review Post Trade Notes"
        case .reviewWhatWentRight:
            "Review What Went Right"
        case .reviewWhatWentWrong:
            "Review What Went Wrong"
        case .reviewOneImprovement:
            "Review One Improvement"
        case .reviewRuleCreatedOrUpdated:
            "Review Rule Updated"
        case .marketIndexTrend:
            "Market Index Trend"
        case .marketSectorStrength:
            "Market Sector Strength"
        case .marketNewsDuringTrade:
            "Market News During Trade"
        case .marketTimeOfDayTag:
            "Market Time Of Day"
        }
    }
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
