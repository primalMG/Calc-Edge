import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var note: Note
    let deleteNote: (() -> Void)?

    @State private var bodyText = AttributedString()
    @State private var bodySelection = AttributedTextSelection()

    @ViewBuilder
    var body: some View {
        #if os(iOS)
        NavigationStack {
            editorContent
                .navigationBarTitleDisplayMode(.inline)
        }
        #else
        editorContent
        #endif
    }

    private var editorContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Title", text: titleBinding)
                .padding(.horizontal, 8)
                .font(.title2.weight(.semibold))
                .textFieldStyle(.plain)
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 10)

            Divider()

            TextEditor(text: bodyTextBinding, selection: $bodySelection)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
        }
        .navigationTitle(NoteFormatting.title(for: note))
        .onAppear(perform: loadBodyText)
        .onChange(of: note.noteId) { _, _ in
            loadBodyText()
        }
        .onChange(of: note.body) { _, newValue in
            guard bodyText.plainText != newValue else { return }
            bodyText = NoteLinkFormatter.attributedString(from: newValue)
            bodySelection = AttributedTextSelection()
        }
        .toolbar {
            if deleteNote != nil {
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive, action: delete) {
                        Image(systemName: "trash")
                    }
                    .help("Delete Note")
                    .tint(.red)
                }

                #if os(iOS)
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                #endif
            }
        }
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { note.title },
            set: { newValue in
                guard note.title != newValue else { return }
                note.title = newValue
                touchNote()
            }
        )
    }

    private var bodyTextBinding: Binding<AttributedString> {
        Binding(
            get: { bodyText },
            set: { newValue in
                let linkedText = NoteLinkFormatter.attributedString(from: newValue)
                bodyText = linkedText

                let plainText = linkedText.plainText
                guard note.body != plainText else { return }
                note.body = plainText
                touchNote()
            }
        )
    }

    private func loadBodyText() {
        bodyText = NoteLinkFormatter.attributedString(from: note.body)
        bodySelection = AttributedTextSelection()
    }

    private func touchNote() {
        note.updatedAt = .now
    }

    private func delete() {
        deleteNote?()
        #if os(iOS)
        dismiss()
        #endif
    }
}

private enum NoteLinkFormatter {
    private static let urlPattern = #/((?:https?:\/\/|www\.)[^\s<>()"]+[^\s<>().,!?;:'"])/#

    static func attributedString(from plainText: String) -> AttributedString {
        attributedString(from: AttributedString(plainText))
    }

    static func attributedString(from source: AttributedString) -> AttributedString {
        let plainText = source.plainText
        var linkedText = source
        linkedText.link = nil

        for match in plainText.matches(of: urlPattern) {
            let matchedText = String(match.output.1)
            guard let url = url(from: matchedText),
                  let lowerBound = AttributedString.Index(match.range.lowerBound, within: linkedText),
                  let upperBound = AttributedString.Index(match.range.upperBound, within: linkedText) else {
                continue
            }

            linkedText[lowerBound..<upperBound].link = url
        }

        return linkedText
    }

    private static func url(from matchedText: String) -> URL? {
        if matchedText.hasPrefix("www.") {
            return URL(string: "https://\(matchedText)")
        }

        return URL(string: matchedText)
    }
}

private extension AttributedString {
    var plainText: String {
        String(characters)
    }
}
