//
//  RiskCalcListView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 19/01/2026.
//

import SwiftUI
import SwiftData

struct RiskCalcListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var stockCalcs: [Stock]

    @Binding var selectedStock: Stock

    var body: some View {
        NavigationStack {
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
            .navigationTitle("Risk Calc")
            .toolbar {
                ToolbarItemGroup {
                    NavigationLink {
                        NewEditRiskCalc(stock: selectedStock)
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .help("New Calculation")
                }
            }
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
