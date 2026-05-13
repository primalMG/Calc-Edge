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
        }
        .navigationTitle(RootTab.more.title)
    }
}

#Preview {
    NavigationStack {
        MoreView()
    }
}
