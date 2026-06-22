import SwiftUI

struct RootSidebarView: View {
    var body: some View {
        List {
            Section("Calculators") {
                NavigationLink(value: CalculatorRoute.stock) {
                    Label("Stock Calc", systemImage: "chart.line.uptrend.xyaxis")
                }

                NavigationLink(value: CalculatorRoute.forex) {
                    Label("Forex Calc", systemImage: "dollarsign.circle")
                }
            }
        }
        .navigationTitle("Calculators")
    }
}

#Preview {
    NavigationStack {
        RootSidebarView()
    }
}
