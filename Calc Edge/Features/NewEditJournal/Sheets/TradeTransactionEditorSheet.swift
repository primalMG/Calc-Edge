import SwiftUI

struct TradeTransactionEditorSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: TradeTransactionDraft

    let state: TradeTransactionEditorState
    let onSave: (TradeTransactionDraft) -> Void

    init(
        state: TradeTransactionEditorState,
        onSave: @escaping (TradeTransactionDraft) -> Void
    ) {
        self.state = state
        self.onSave = onSave
        _draft = State(initialValue: state.draft)
    }

    var body: some View {
        NavigationStack {
            Form {
                TradeTransactionBasicsFields(draft: $draft)
                TradeTransactionValueFields(draft: $draft)
                TradeTransactionNoteFields(note: $draft.note)
            }
            .navigationTitle(state.transaction == nil ? "New Transaction" : "Edit Transaction")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: dismiss.callAsFunction)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
        }
        #if os(macOS)
        .padding()
        .frame(minWidth: 420, minHeight: 360)
        #endif
    }

    private var canSave: Bool {
        if draft.action == .dividend {
            return (draft.amount ?? -1) >= 0 && (draft.exchangeRate ?? 0) >= 0 && (draft.fees ?? 0) >= 0
        }

        return draft.quantity >= 0 && draft.price >= 0 && (draft.amount ?? 0) >= 0 && (draft.exchangeRate ?? 0) >= 0 && (draft.fees ?? 0) >= 0
    }

    private var normalizedDraft: TradeTransactionDraft {
        var normalized = draft
        normalized.note = draft.note?.trimmingCharacters(in: .whitespacesAndNewlines)
        if normalized.note?.isEmpty == true {
            normalized.note = nil
        }
        if normalized.action != .dividend {
            normalized.amount = nil
        }
        return normalized
    }

    private func save() {
        onSave(normalizedDraft)
        dismiss()
    }
}

private struct TradeTransactionBasicsFields: View {
    @Binding var draft: TradeTransactionDraft

    var body: some View {
        Section {
            DatePicker("Date", selection: $draft.date, displayedComponents: [.date])

            Picker("Action", selection: $draft.action) {
                ForEach(TradeTransactionAction.allCases, id: \.self) { action in
                    Label(action.displayName, systemImage: action.systemImage)
                        .tag(action)
                }
            }
            .pickerStyle(.menu)
        }
    }
}

private struct TradeTransactionValueFields: View {
    @Binding var draft: TradeTransactionDraft

    var body: some View {
        Section {
            if draft.action == .dividend {
                TextField("Amount", text: optionalDecimalBinding($draft.amount, fractionDigits: 2))
            } else {
                TextField("Quantity", text: decimalBinding($draft.quantity))
                TextField("Price", text: decimalBinding($draft.price))
            }

            TextField("Exchange Rate", text: optionalDecimalBinding($draft.exchangeRate))
            TextField("Fees", text: optionalDecimalBinding($draft.fees))
        }
    }
}

private struct TradeTransactionNoteFields: View {
    @Binding var note: String?

    var body: some View {
        Section {
            TextField("Note", text: optionalTextBinding($note), axis: .vertical)
                .lineLimit(3...5)
        }
    }
}
