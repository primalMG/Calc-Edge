import SwiftUI
import SwiftData

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Bindable var note: Note
    let deleteNote: (() -> Void)?

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                TextField("Title", text: $note.title)
                    .padding(.horizontal, 8)
                    .font(.title2.weight(.semibold))
                    .textFieldStyle(.plain)
                    .padding(.horizontal)
                    .padding(.top)
                    .padding(.bottom, 10)
                
                Divider()
                
                TextEditor(text: $note.body)
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
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
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
            .onChange(of: note.title) { _, _ in
                touchNote()
            }
            .onChange(of: note.body) { _, _ in
                touchNote()
            }
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
