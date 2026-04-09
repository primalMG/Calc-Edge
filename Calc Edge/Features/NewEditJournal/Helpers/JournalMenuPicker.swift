import SwiftUI

struct JournalMenuPicker<SelectionValue: Hashable, Content: View>: View {
    @Binding var selection: SelectionValue

    private let title: String
    private let content: Content

    init(
        _ title: String,
        selection: Binding<SelectionValue>,
        @ViewBuilder content: () -> Content
    ) {
        _selection = selection
        self.title = title
        self.content = content()
    }

    var body: some View {
        #if os(iOS)
        Menu {
            Picker("", selection: $selection) {
                content
            }
            .labelsHidden()
        } label: {
            HStack(spacing: 5) {
                Text(title)
                    .lineLimit(1)

                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .labelsHidden()
        .tint(.primary)
        #else
        Picker("", selection: $selection) {
            content
        }
        .labelsHidden()
        .frame(maxWidth: .infinity, alignment: .leading)
        #endif
    }
}
