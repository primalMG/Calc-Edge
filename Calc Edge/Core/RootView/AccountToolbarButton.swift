import SwiftUI

struct AccountToolbarButton: ToolbarContent {
    let action: () -> Void

    var body: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .topBarLeading) {
            button
        }
        #else
        ToolbarItem {
            button
        }
        #endif
    }

    private var button: some View {
        Button(action: action) {
            Image(systemName: "person.circle.fill")
        }
        .help("Accounts")
    }
}
