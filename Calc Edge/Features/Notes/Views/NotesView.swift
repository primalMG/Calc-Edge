import SwiftUI
import SwiftData

struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]

    @State private var selectedNoteID: UUID?

    var body: some View {
        content
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: createNote) {
                        Image(systemName: "square.and.pencil")
                    }
                    .help("New Note")
                }
            }
            .onAppear(perform: keepSelectionInSync)
            .onChange(of: notes.map(\.noteId)) { _, _ in
                keepSelectionInSync()
            }
    }

    @ViewBuilder
    private var content: some View {
        if notes.isEmpty {
            NotesEmptyStateView(createNote: createNote)
        } else {
            #if os(macOS)
            HSplitView {
                NotesListView(
                    notes: notes,
                    selectedNoteID: $selectedNoteID,
                    deleteItems: deleteItems,
                    deleteNote: delete
                )
                .frame(minWidth: 260, idealWidth: 320, maxWidth: 420)

                noteDetail
                    .frame(minWidth: 420)
            }
            #else
            NotesListView(
                notes: notes,
                selectedNoteID: $selectedNoteID,
                deleteItems: deleteItems,
                deleteNote: delete
            )
            #endif
        }
    }

    @ViewBuilder
    private var noteDetail: some View {
        if let selectedNote {
            NoteEditorView(note: selectedNote) {
                delete(selectedNote)
            }
        } else {
            ContentUnavailableView("Select a Note", systemImage: "note.text")
        }
    }

    private var selectedNote: Note? {
        guard let selectedNoteID else { return nil }
        return note(with: selectedNoteID)
    }

    private func note(with noteID: UUID) -> Note? {
        notes.first(where: { $0.noteId == noteID })
    }

    private func createNote() {
        let note = Note()
        modelContext.insert(note)
        selectedNoteID = note.noteId
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                delete(notes[index])
            }
        }
    }

    private func delete(_ note: Note) {
        if selectedNoteID == note.noteId {
            selectedNoteID = nil
        }

        modelContext.delete(note)
        keepSelectionInSync()
    }

    private func keepSelectionInSync() {
        guard !notes.isEmpty else {
            selectedNoteID = nil
            return
        }

        if let selectedNoteID,
           notes.contains(where: { $0.noteId == selectedNoteID }) {
            return
        }

        #if os(macOS)
        selectedNoteID = notes.first?.noteId
        #endif
    }
}

#Preview {
    NotesView()
        .modelContainer(for: Note.self, inMemory: true)
}
