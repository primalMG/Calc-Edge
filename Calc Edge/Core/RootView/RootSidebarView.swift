import SwiftUI
import SwiftData

struct RootSidebarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var stockCalcs: [Stock]

    @Binding var presentSheet: Bool
    @Binding var selectedStock: Stock

    var body: some View {
        List {
            ForEach(stockCalcs) { stock in
                NavigationLink {
                    StockCalcView(stock: stock)
                } label: {
                    Text(stock.ticker)
                }
            }
            .onDelete(perform: deleteItems)
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

                NavigationLink {
                    NewEditRiskCalc(stock: selectedStock)
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .help("New Calculation")
            }
        }
        .sheet(isPresented: $presentSheet) {
            AccountsView()
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(stockCalcs[index])
            }
        }
    }
}
