import SwiftUI

struct NotesListView: View {
    let notes: [Note]
    @Binding var selectedNoteID: UUID?
    let deleteItems: (IndexSet) -> Void
    let deleteNote: (Note) -> Void
    
    #if os(iOS)
    @State private var note: Note?
    #endif

    var body: some View {
        List(selection: $selectedNoteID) {
            ForEach(notes) { note in
                #if os(macOS)
                NoteRow(note: note)
                    .tag(note.noteId)
                #else
                Button {
                    self.note = note
                } label: {
                    NoteRow(note: note)
                }
                .buttonStyle(.plain)
                #endif
            }
            .onDelete(perform: deleteItems)
        }
        #if os(macOS)
        .listStyle(.sidebar)
        #elseif os(iOS)
        .sheet(item: $note) { note in
            NoteEditorView(note: note) {
                deleteNote(note)
            }
            .presentationDetents([.fraction(0.26), .fraction(0.5)])
        }
        #endif
    }
}
