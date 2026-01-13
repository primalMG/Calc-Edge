//
//  ContentView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 11/01/2026.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var stockCalcs: [Stock]
    
    @State private var presentSheet: Bool = false
    @State private var presentCalcSheet: Bool = false
    
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
        NavigationSplitView {
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
            
        } detail: {
            Text("No Stock Calcution Selected")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(timestamp: Date())
            modelContext.insert(newItem)
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

#Preview {
    RootView()
        .modelContainer(for: Item.self, inMemory: true)
}
