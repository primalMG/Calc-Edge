import SwiftUI

struct RootTabScene: View {
    let tab: RootTab
    @Binding var selectedStock: Stock

    var body: some View {
        NavigationStack {
            content
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .journal:
            TradeJournalView()
        case .insights:
            JournalInsightsView()
        case .reviewCalendar:
            TradingReviewCalendarView()
        case .calculators:
            RootSidebarView()
        case .stockCalc:
            RiskCalcListView(selectedStock: $selectedStock)
        case .forexCalc:
            ForexCalcView()
        case .notes:
            NotesView()
        case .rulebook:
            RulebookContent()
        case .playbook:
            SetupPlaybookContent()
        case .accounts:
            AccountsContent(showsCloseButton: false)
        case .suggestions:
            SuggestionsView()
        case .privacy:
            PrivacyTermsView()
        case .clearData:
            ClearAllDataView()
        case .more:
            MoreView()
        }
    }
}
