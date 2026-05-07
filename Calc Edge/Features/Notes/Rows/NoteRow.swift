import SwiftUI

struct NoteRow: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(NoteFormatting.title(for: note))
                    .font(.headline)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(NoteFormatting.editedDate(note.updatedAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(NoteFormatting.preview(for: note))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(.vertical, 4)
    }
}
