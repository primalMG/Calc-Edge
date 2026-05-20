import SwiftUI

struct MoreView: View {
    var body: some View {
        List {
            
            Section {
                NavigationLink {
                    TradingReviewCalendarView()
                } label: {
                    Label(RootTab.reviewCalendar.title, systemImage: RootTab.reviewCalendar.systemImage)
                }
            }
            
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
        }
        .navigationTitle(RootTab.more.title)
    }
}

#Preview {
    NavigationStack {
        MoreView()
    }
}
