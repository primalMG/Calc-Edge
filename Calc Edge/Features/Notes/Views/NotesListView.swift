import SwiftUI

struct NotesListView: View {
    let notes: [Note]
    @Binding var selectedNoteID: UUID?
    let deleteItems: (IndexSet) -> Void
    let deleteNote: (Note) -> Void

    var body: some View {
        List(selection: $selectedNoteID) {
            ForEach(notes) { note in
                #if os(macOS)
                NoteRow(note: note)
                    .tag(note.noteId)
                #else
                NavigationLink {
                    NoteEditorView(note: note) {
                        deleteNote(note)
                    }
                } label: {
                    NoteRow(note: note)
                }
                #endif
            }
            .onDelete(perform: deleteItems)
        }
        #if os(macOS)
        .listStyle(.sidebar)
        #endif
    }
}
