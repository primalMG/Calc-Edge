import SwiftUI

struct RootSidebarView: View {
    @State private var selectedStock = Stock.emptyDraft

    var body: some View {
        List {
            Section("Calculators") {
                NavigationLink {
                    RiskCalcListView(selectedStock: $selectedStock)
                } label: {
                    Label("Stock Calc", systemImage: "chart.line.uptrend.xyaxis")
                }

                NavigationLink {
                    ForexCalcView()
                } label: {
                    Label("Forex Calc", systemImage: "dollarsign.circle")
                }
            }
        }
        .navigationTitle("Calculators")
    }
}

#Preview {
    RootSidebarView()
}
