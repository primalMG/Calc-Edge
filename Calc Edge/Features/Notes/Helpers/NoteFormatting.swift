import Foundation

enum NoteFormatting {
    static func title(for note: Note) -> String {
        let trimmedTitle = note.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            return trimmedTitle
        }

        let firstBodyLine = note.body
            .components(separatedBy: .newlines)
            .first?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        return firstBodyLine.isEmpty ? "Untitled Note" : firstBodyLine
    }

    static func preview(for note: Note) -> String {
        let trimmedBody = note.body.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedBody.isEmpty ? "No additional text" : trimmedBody
    }

    static func editedDate(_ date: Date) -> String {
        date.formatted(.relative(presentation: .named))
    }
}
