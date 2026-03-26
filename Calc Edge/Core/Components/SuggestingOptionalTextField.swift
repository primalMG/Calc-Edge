import SwiftUI
import SwiftData

struct SuggestingOptionalTextField: View {
    let field: TradeSuggestionField
    @Binding var text: String?

    @Query(sort: \TradeFieldSuggestion.lastUsedAt, order: .reverse)
    private var savedSuggestions: [TradeFieldSuggestion]

    var body: some View {
        TextField("", text: optionalTextBinding($text))
        #if os(macOS)
            .textInputSuggestions(matchingSuggestions, id: \.uniqueKey) { suggestion in
                Text(suggestion.value)
                    .textInputCompletion(suggestion.value)
            }
        #endif
    }

    private var matchingSuggestions: [TradeFieldSuggestion] {
        let query = text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let fieldSuggestions = savedSuggestions.filter { $0.field == field.rawValue }

        guard !query.isEmpty else {
            return Array(fieldSuggestions.prefix(6))
        }

        return Array(
            fieldSuggestions
                .filter { $0.value.localizedCaseInsensitiveContains(query) }
                .prefix(6)
        )
    }
}
