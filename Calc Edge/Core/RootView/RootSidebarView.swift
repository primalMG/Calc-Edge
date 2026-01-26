import SwiftUI

struct RootSidebarView: View {
    @State private var presentSheet: Bool = false
    @State private var selectedStock = Stock(ticker: "",
                                             entryPrice: 0.0,
                                             riskPercentage: 0.0,
                                             stopLoss: 0.0,
                                             shareCount: 0.0,
                                             targetPrice: 0.0,
                                             accountUsed: "",
                                             balanceAtTrade: 0.0,
                                             amountRisked: 0.0)

    var body: some View {
        List {
            NavigationLink {
                DashboardView()
            } label: {
                Label("Dashboard", systemImage: "house")
            }

            NavigationLink {
                RiskCalcListView(selectedStock: $selectedStock)
            } label: {
                Label("Risk Calc", systemImage: "chart.line.uptrend.xyaxis")
            }

            NavigationLink {
                TradeJournalView()
            } label: {
                Label("Trade Journal", systemImage: "book")
            }
        }
        .navigationSplitViewColumnWidth(min: 250, ideal: 300)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    presentSheet.toggle()
                } label: {
                    Image(systemName: "person.circle.fill")
                }
                .help("Accounts")
            }
        }
        .sheet(isPresented: $presentSheet) {
            AccountsView()
        }
    }
}
