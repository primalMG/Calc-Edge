import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var note: Note
    let deleteNote: (() -> Void)?

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

            TextEditor(text: bodyBinding)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(.gray.secondary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 25))
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
        }
        .navigationTitle(NoteFormatting.title(for: note))
        .toolbar {
            if deleteNote != nil {
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive, action: delete) {
                        Image(systemName: "trash")
                    }
                    .help("Delete Note")
                    .tint(.red)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .help("Close Note Editor")
                }
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

    private var bodyBinding: Binding<String> {
        Binding(
            get: { note.body },
            set: { newValue in
                guard note.body != newValue else { return }
                note.body = newValue
                touchNote()
            }
        )
    }

    private func touchNote() {
        note.updatedAt = .now
    }

    private func delete() {
        deleteNote?()
        dismiss()
    }
}
