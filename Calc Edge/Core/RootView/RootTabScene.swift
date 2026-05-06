import SwiftUI

struct RootTabScene: View {
    let tab: RootTab
    @Binding var selectedStock: Stock
    let presentAccounts: () -> Void

    var body: some View {
        NavigationStack {
            content
                .toolbar {
                    AccountToolbarButton(action: presentAccounts)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .dashboard:
            DashboardView()
        case .journal:
            TradeJournalView()
        case .insights:
            JournalInsightsView()
        case .calculators:
            RootSidebarView()
        case .stockCalc:
            RiskCalcListView(selectedStock: $selectedStock)
        case .forexCalc:
            ForexCalcView()
        case .suggestions:
            SuggestionsView()
        }
    }
}
