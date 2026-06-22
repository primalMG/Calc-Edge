import SwiftUI

struct RootTabScene: View {
    let tab: RootTab
    @Binding var selectedStock: Stock
    @State private var calculatorPath: [CalculatorRoute]

    init(
        tab: RootTab,
        selectedStock: Binding<Stock>,
        initialCalculatorRoute: CalculatorRoute? = nil
    ) {
        self.tab = tab
        _selectedStock = selectedStock
        _calculatorPath = State(
            initialValue: tab == .calculators ? initialCalculatorRoute.map { [$0] } ?? [] : []
        )
    }

    var body: some View {
        NavigationStack(path: $calculatorPath) {
            content
                .navigationDestination(for: CalculatorRoute.self) { route in
                    calculatorDestination(route)
                }
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

    @ViewBuilder
    private func calculatorDestination(_ route: CalculatorRoute) -> some View {
        switch route {
        case .stock:
            RiskCalcListView(selectedStock: $selectedStock)
        case .forex:
            ForexCalcView()
        }
    }
}
