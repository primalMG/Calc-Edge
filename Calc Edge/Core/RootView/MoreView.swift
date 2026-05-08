import SwiftUI

struct MoreView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    AccountsContent(showsCloseButton: false)
                } label: {
                    Label(RootTab.accounts.title, systemImage: RootTab.accounts.systemImage)
                }

                NavigationLink {
                    SuggestionsView()
                } label: {
                    Label(RootTab.suggestions.title, systemImage: RootTab.suggestions.systemImage)
                }
            }
        }
        .navigationTitle(RootTab.more.title)
    }
}

#Preview {
    NavigationStack {
        MoreView()
    }
}
