import SwiftUI

struct JournalSectionContainer<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct JournalField<Content: View>: View {
    let label: String
    let content: Content
    #if os(iOS)
    @State private var suggestionsVisible = false
    #endif

    init(_ label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        #if os(iOS)
        .animation(.easeInOut(duration: 0.18), value: suggestionsVisible)
        .onPreferenceChange(JournalFieldSuggestionsVisibleKey.self) { isVisible in
            withAnimation(.easeInOut(duration: 0.18)) {
                suggestionsVisible = isVisible
            }
        }
        #endif
    }
}

struct JournalFieldSuggestionsVisibleKey: PreferenceKey {
    static let defaultValue = false

    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = value || nextValue()
    }
}
