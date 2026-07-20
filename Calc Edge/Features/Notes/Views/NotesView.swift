import SwiftUI
import SwiftData

struct NotesView: View {
    @State private var fetchLimit = PlatformPageSize.initial

    var body: some View {
        NotesPagedView(fetchLimit: fetchLimit) {
            fetchLimit += PlatformPageSize.increment
        }
    }
}

private struct NotesPagedView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var notes: [Note]

    @State private var selectedNoteID: UUID?
    @State private var toast: ToastConfiguration?

    let fetchLimit: Int
    let loadMore: () -> Void

    init(fetchLimit: Int, loadMore: @escaping () -> Void) {
        self.fetchLimit = fetchLimit
        self.loadMore = loadMore

        var descriptor = FetchDescriptor<Note>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = fetchLimit
        _notes = Query(descriptor)
    }

    var body: some View {
        content
            .navigationTitle("Notes")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: createNote) {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("New Note")
                    .help("New Note")
                }

                #if DEBUG
                ToolbarItem(placement: .primaryAction) {
                    DebugMockDataMenu(seed: seedMockData, clear: clearMockData)
                }
                #endif
            }
            .toast($toast)
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
                    deleteNote: delete,
                    canLoadMore: canLoadMore,
                    loadMore: loadMore
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
                deleteNote: delete,
                canLoadMore: canLoadMore,
                loadMore: loadMore
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

    private var canLoadMore: Bool {
        notes.count >= fetchLimit
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
        try? modelContext.saveIfNeeded()
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

    #if DEBUG
    private func seedMockData() {
        performMockDataAction(successTitle: "Mock Data Ready") {
            let count = try DebugMockData.seedNotes(in: modelContext)
            return "Added \(count) notes."
        }
    }

    private func clearMockData() {
        performMockDataAction(successTitle: "Mock Data Cleared") {
            let count = try DebugMockData.clearNotes(in: modelContext)
            return "Removed \(count) demo notes."
        }
    }

    private func performMockDataAction(
        successTitle: String,
        action: () throws -> String
    ) {
        do {
            toast = ToastConfiguration(title: successTitle, message: try action(), state: .success)
        } catch {
            toast = ToastConfiguration(title: "Mock Data Failed", message: error.localizedDescription, state: .error, duration: 4)
        }
    }
    #endif
}

#Preview {
    NotesView()
        .modelContainer(for: Note.self, inMemory: true)
}
