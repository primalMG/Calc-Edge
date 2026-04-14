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
    @Query(sort: \Stock.createdAt, order: .reverse) private var stockCalcs: [Stock]

    @Binding var selectedStock: Stock
    #if os(macOS)
    @State private var selectedStockID: UUID?
    #endif
    @State private var presentSheet: Bool = false

    var body: some View {
        listContent
        .navigationTitle("Stock Calc")
        .toolbar {
            ToolbarItemGroup {
                Button {
                    selectedStock = Stock(ticker: "", entryPrice: 0.0, riskPercentage: 0.0, stopLoss: 0.0, shareCount: 0.0, targetPrice: 0.0, accountUsed: "", balanceAtTrade: 0.0, amountRisked: 0.0)
                    presentSheet.toggle()
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .help("New Calculation")
                .sheet(isPresented: $presentSheet) {
                    NewEditRiskCalc(stock: selectedStock, isNew: true)
                }
            }
        }
        #if os(macOS)
        .inspector(isPresented: inspectorIsPresented) {
            if let inspectorStock {
                StockCalcView(stock: inspectorStock)
                    .inspectorColumnWidth(min: 450, ideal: 540, max: 800)
            } else {
                ContentUnavailableView("Select a Calculation", systemImage: "chart.line.uptrend.xyaxis")
                    .inspectorColumnWidth(min: 450, ideal: 540, max: 800)
            }
        }
        .frame(minWidth: 300, idealWidth: 320)
        .onAppear(perform: syncInitialSelection)
        .onChange(of: selectedStockID, updateSelectedStock)
        .onChange(of: stockCalcs.count) { _, _ in
            keepSelectionInSync()
        }
        #endif
    }

    #if os(macOS)
    private var inspectorStock: Stock? {
        guard let selectedStockID else { return nil }
        return stockCalcs.first(where: { $0.id == selectedStockID })
    }

    private var inspectorIsPresented: Binding<Bool> {
        Binding(
            get: { selectedStockID != nil },
            set: { isPresented in
                if !isPresented {
                    selectedStockID = nil
                }
            }
        )
    }
    #endif

    @ViewBuilder
    private var listContent: some View {
        #if os(macOS)
        List(selection: $selectedStockID) {
            ForEach(stockCalcs) { stock in
                RiskCalcRow(stock: stock)
                    .tag(stock.id)
            }
            .onDelete(perform: deleteItems)
        }
        #else
        List {
            ForEach(stockCalcs) { stock in
                NavigationLink {
                    StockCalcView(stock: stock)
                } label: {
                    RiskCalcRow(stock: stock)
                }
            }
            .onDelete(perform: deleteItems)
        }
        #endif
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                #if os(macOS)
                if stockCalcs[index].id == selectedStockID {
                    selectedStockID = nil
                }
                #endif
                modelContext.delete(stockCalcs[index])
            }
        }
    }

    #if os(macOS)
    private func syncInitialSelection() {
        if let matchingStock = stockCalcs.first(where: { $0.id == selectedStock.id }) {
            selectedStockID = matchingStock.id
            return
        }

        if selectedStockID == nil {
            selectedStockID = stockCalcs.first?.id
        }
    }

    private func updateSelectedStock(oldValue: UUID?, newValue: UUID?) {
        guard let newValue,
              let stock = stockCalcs.first(where: { $0.id == newValue }) else {
            return
        }

        selectedStock = stock
    }

    private func keepSelectionInSync() {
        if let selectedStockID,
           stockCalcs.contains(where: { $0.id == selectedStockID }) {
            return
        }

        self.selectedStockID = stockCalcs.first?.id
    }
    #endif
}

private struct RiskCalcRow: View {
    let stock: Stock

    private var lossDifference: Double {
        stock.entryPrice - stock.stopLoss
    }

    private var lossTotal: Double {
        lossDifference * stock.shareCount
    }

    private var profitDifference: Double {
        stock.targetPrice - stock.entryPrice
    }

    private var profitTotal: Double {
        profitDifference * stock.shareCount
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(stock.ticker)
                    .font(.headline)

                Spacer()

                if let updatedAt = stock.updatedAt {
                    Text("Updated \(updatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Label(stock.accountUsed, systemImage: "person.crop.circle")
                Label("Profit \(profitTotal.formatted(.number.precision(.fractionLength(2))))", systemImage: "arrow.up.right")
                    .foregroundStyle(.green)
                Label("Loss \(lossTotal.formatted(.number.precision(.fractionLength(2))))", systemImage: "arrow.down.right")
                    .foregroundStyle(.red)
            }
            .font(.subheadline)

            Text("Created \(stock.createdAt.formatted(date: .abbreviated, time: .omitted))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
