import SwiftUI

struct NotesEmptyStateView: View {
    let createNote: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No Notes", systemImage: "note.text")
        } description: {
            Text("Create a note for ideas, reminders, and general market thoughts.")
        } actions: {
            Button(action: createNote) {
                Label("New Note", systemImage: "square.and.pencil")
            }
        }
    }
}
