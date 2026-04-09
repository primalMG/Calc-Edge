import Foundation

enum TradeJournalDetailSuggestionValues {
    static func currentValues(for trade: Trade) -> [TradeSuggestionField: String] {
        var values: [TradeSuggestionField: String] = [:]

        updateSuggestionValue(&values, field: .strategyName, with: trade.strategyName)
        updateSuggestionValue(&values, field: .setupType, with: trade.setupType)
        updateSuggestionValue(&values, field: .timeframe, with: trade.timeframe)
        updateSuggestionValue(&values, field: .catalyst, with: trade.catalyst)

        if let review = trade.review {
            updateSuggestionValue(&values, field: .reviewMistakeType, with: review.mistakeType)
            updateSuggestionValue(&values, field: .reviewPostTradeNotes, with: review.postTradeNotes)
            updateSuggestionValue(&values, field: .reviewWhatWentRight, with: review.whatWentRight)
            updateSuggestionValue(&values, field: .reviewWhatWentWrong, with: review.whatWentWrong)
            updateSuggestionValue(&values, field: .reviewOneImprovement, with: review.oneImprovement)
            updateSuggestionValue(&values, field: .reviewRuleCreatedOrUpdated, with: review.ruleCreatedOrUpdated)
        }

        if let context = trade.context {
            updateSuggestionValue(&values, field: .marketIndexTrend, with: context.indexTrend)
            updateSuggestionValue(&values, field: .marketSectorStrength, with: context.sectorStrength)
            updateSuggestionValue(&values, field: .marketNewsDuringTrade, with: context.newsDuringTrade)
            updateSuggestionValue(&values, field: .marketTimeOfDayTag, with: context.timeOfDayTag)
        }

        return values
    }

    private static func updateSuggestionValue(
        _ values: inout [TradeSuggestionField: String],
        field: TradeSuggestionField,
        with value: String?
    ) {
        guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmedValue.isEmpty else {
            return
        }

        values[field] = trimmedValue
    }
}
