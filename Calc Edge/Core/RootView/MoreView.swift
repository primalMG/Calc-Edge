import SwiftUI

struct MoreView: View {
    var body: some View {
        List {
            Section("Books") {
                NavigationLink {
                    RulebookContent()
                } label: {
                    Label(RootTab.rulebook.title, systemImage: RootTab.rulebook.systemImage)
                }

                NavigationLink {
                    SetupPlaybookContent()
                } label: {
                    Label(RootTab.playbook.title, systemImage: RootTab.playbook.systemImage)
                }
            }
            
            Section("Manage") {
                NavigationLink {
                    SuggestionsView()
                } label: {
                    Label(RootTab.suggestions.title, systemImage: RootTab.suggestions.systemImage)
                }
                
                NavigationLink {
                    NotesView()
                } label: {
                    Label(RootTab.notes.title, systemImage: RootTab.notes.systemImage)
                }

                
                NavigationLink {
                    AccountsContent(showsCloseButton: false)
                } label: {
                    Label(RootTab.accounts.title, systemImage: RootTab.accounts.systemImage)
                }
            }

            Section("App") {
                NavigationLink {
                    PrivacyTermsView()
                } label: {
                    Label(RootTab.privacy.title, systemImage: RootTab.privacy.systemImage)
                }

                NavigationLink {
                    ClearAllDataView()
                } label: {
                    Label(RootTab.clearData.title, systemImage: RootTab.clearData.systemImage)
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
