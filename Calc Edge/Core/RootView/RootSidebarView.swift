import SwiftUI

struct RootSidebarView: View {
    @Binding var presentSheet: Bool
    @Binding var selectedStock: Stock

    var body: some View {
        List {
            NavigationLink {
                DashboardView(selectedStock: $selectedStock)
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
