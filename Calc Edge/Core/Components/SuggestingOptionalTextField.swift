import SwiftUI
import SwiftData

struct SuggestingOptionalTextField: View {
    let field: TradeSuggestionField
    @Binding var text: String?

    @Query(sort: \TradeFieldSuggestion.lastUsedAt, order: .reverse)
    private var savedSuggestions: [TradeFieldSuggestion]

    #if os(iOS)
    @FocusState private var isFocused: Bool
    #endif

    var body: some View {
        #if os(iOS)
        VStack(alignment: .leading, spacing: 8) {
            TextField("", text: optionalTextBinding($text))
                .focused($isFocused)

            if isFocused, !matchingSuggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(matchingSuggestions, id: \.uniqueKey) { suggestion in
                            Button {
                                text = suggestion.value
                                isFocused = false
                            } label: {
                                Text(suggestion.value)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.thinMaterial)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 1)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .preference(
            key: JournalFieldSuggestionsVisibleKey.self,
            value: isFocused && !matchingSuggestions.isEmpty
        )
        #else
        TextField("", text: optionalTextBinding($text))
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
