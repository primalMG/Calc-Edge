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

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(stockCalcs) { stock in
                    NavigationLink {
//                        Text("Item at \(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))")
                    } label: {
                        StockCalcView(stock: stock)
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

                    Button {
                        presentCalcSheet.toggle()
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .help("New Calculation")

                }
            }
            .sheet(isPresented: $presentSheet) {
                AccountsView()
            }
            .sheet(isPresented: $presentCalcSheet) {
//                RiskCalcView(stock: <#T##Stock#>, accounts: <#T##[Account]#>)
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
