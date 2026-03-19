import SwiftUI
import SwiftData

struct StrategySection: View {
    @Query(sort: \TradeFieldSuggestion.lastUsedAt, order: .reverse)
    private var savedSuggestions: [TradeFieldSuggestion]
    @Bindable var trade: Trade

    var body: some View {
        JournalSectionContainer("Strategy") {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                JournalField("Strategy Name") {
                    TextField("", text: optionalTextBinding($trade.strategyName))
                        .textInputSuggestions(matchingStrategySuggestions, id: \.uniqueKey) { suggestion in
                            Text(suggestion.value)
                                .textInputCompletion(suggestion.value)
                        }
                }
                
                JournalField("Setup Type") {
                    TextField("", text: optionalTextBinding($trade.setupType))
                }
                
                JournalField("Timeframe") {
                    TextField("", text: optionalTextBinding($trade.timeframe))
                }
                
                JournalField("Thesis") {
                    TextField("", text: optionalTextBinding($trade.thesis))
                }
                
                JournalField("Catalyst") {
                    TextField("", text: optionalTextBinding($trade.catalyst))
                }
                
                Stepper("Confidence Score: \(trade.confidenceScore)", value: $trade.confidenceScore, in: 1...5)
                
                Toggle("A+ Setup", isOn: $trade.isAPlusSetup)
            }
        }
    }
    
    private let columns = [
        GridItem(.flexible(minimum: 140), spacing: 12),
        GridItem(.flexible(minimum: 140), spacing: 12),
        GridItem(.flexible(minimum: 140), spacing: 12)
    ]

    private var matchingStrategySuggestions: [TradeFieldSuggestion] {
        let query = trade.strategyName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let strategySuggestions = savedSuggestions.filter {
            $0.field == StrategySuggestionField.strategyName.rawValue
        }

        guard !query.isEmpty else {
            return Array(strategySuggestions.prefix(6))
        }

        return strategySuggestions
            .filter { suggestion in
                suggestion.value.localizedCaseInsensitiveContains(query)
            }
            .prefix(6)
            .map { $0 }
    }
}

enum StrategySuggestionField: String {
    case strategyName
}
