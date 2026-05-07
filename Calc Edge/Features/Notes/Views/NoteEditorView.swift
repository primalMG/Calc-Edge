import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var note: Note
    let deleteNote: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Title", text: $note.title)
                .font(.title2.weight(.semibold))
                .textFieldStyle(.plain)
                .padding(.horizontal)
                .padding(.top)
                .padding(.bottom, 10)

            Divider()

            TextEditor(text: $note.body)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .navigationTitle(NoteFormatting.title(for: note))
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .toolbar {
            if deleteNote != nil {
                ToolbarItem(placement: .automatic) {
                    Button(role: .destructive, action: delete) {
                        Image(systemName: "trash")
                    }
                    .help("Delete Note")
                }
            }
        }
        .onChange(of: note.title) { _, _ in
            touchNote()
        }
        .onChange(of: note.body) { _, _ in
            touchNote()
        }
    }

    private func touchNote() {
        note.updatedAt = .now
    }

    private func delete() {
        deleteNote?()
        dismiss()
    }
}
