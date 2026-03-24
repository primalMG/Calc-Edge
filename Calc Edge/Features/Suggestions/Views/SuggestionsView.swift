import SwiftUI
import SwiftData

struct SuggestionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TradeFieldSuggestion.lastUsedAt, order: .reverse)
    private var suggestions: [TradeFieldSuggestion]

    @State private var selectedField: TradeSuggestionField = .strategyName

    var body: some View {
        List {
            Section("Field") {
                Picker("Suggestion Field", selection: $selectedField) {
                    ForEach(TradeSuggestionField.allCases, id: \.self) { field in
                        Text(field.title)
                            .tag(field)
                    }
                }
                #if os(iOS)
                .pickerStyle(.navigationLink)
                #endif
            }

            Section(selectedField.title) {
                if filteredSuggestions.isEmpty {
                    ContentUnavailableView(
                        "No Suggestions",
                        systemImage: "text.badge.plus",
                        description: Text("Suggestions for this field appear here after you reuse values in the journal.")
                    )
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredSuggestions) { suggestion in
                        SuggestionRow(suggestion: suggestion) {
                            deleteSuggestion(suggestion)
                        }
                    }
                    .onDelete(perform: deleteSuggestions)
                }
            }
        }
        .navigationTitle("Suggestions")
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
            #endif
        }
    }

    private var filteredSuggestions: [TradeFieldSuggestion] {
        suggestions.filter { $0.field == selectedField.rawValue }
    }

    private func deleteSuggestions(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredSuggestions[index])
            }
            try? modelContext.save()
        }
    }

    private func deleteSuggestion(_ suggestion: TradeFieldSuggestion) {
        withAnimation {
            modelContext.delete(suggestion)
            try? modelContext.save()
        }
    }
}

private struct SuggestionRow: View {
    let suggestion: TradeFieldSuggestion
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(suggestion.value)
                .fontWeight(.medium)

            HStack(spacing: 12) {
                Text("Used \(suggestion.useCount)x")
                Text("Last used \(suggestion.lastUsedAt.formatted(date: .abbreviated, time: .shortened))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
