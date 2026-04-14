//
//  StockCalc.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 12/01/2026.
//

import SwiftUI
import SwiftData

struct StockCalcView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var toggleAlert: Bool = false
    @State private var presentSheet: Bool = false

    @Bindable var stock: Stock

    private let statColumns = [
        GridItem(.adaptive(minimum: 180), spacing: 12)
    ]

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

    private var riskRewardRatio: Double {
        lossTotal == 0 ? 0 : profitTotal / lossTotal
    }

    private var riskRewardRatioColor: Color {
        riskRewardRatio > 1.5 ? .green : .red
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                InfoSection(title: "Overview") {
                    LazyVGrid(columns: statColumns, alignment: .leading, spacing: 12) {
                        InfoStatCard(
                            title: "Potential Profit",
                            value: formatCurrency(profitTotal),
                            accentColor: .green
                        )
                        InfoStatCard(
                            title: "Potential Loss",
                            value: formatCurrency(lossTotal),
                            accentColor: .red
                        )
                        InfoStatCard(
                            title: "Risk / Reward",
                            value: formatNumber(riskRewardRatio),
                            accentColor: riskRewardRatioColor
                        )
                        InfoStatCard(
                            title: "Amount Risked",
                            value: formatCurrency(stock.amountRisked)
                        )
                    }
                }

                InfoSection(title: "Profit Breakdown") {
                    InfoRow(title: "Technical Target", detail: formatCurrency(stock.targetPrice))
                    InfoRow(title: "Profit Per Share", detail: formatCurrency(profitDifference))
                    InfoRow(title: "Potential Profit", detail: formatCurrency(profitTotal))
                }

                InfoSection(title: "Loss Breakdown") {
                    InfoRow(title: "Stop Loss", detail: formatCurrency(stock.stopLoss))
                    InfoRow(title: "Loss Per Share", detail: formatCurrency(lossDifference))
                    InfoRow(title: "Potential Loss", detail: formatCurrency(lossTotal))
                }

                InfoSection(title: "Position Details") {
                    InfoRow(title: "Ticker", detail: stock.ticker)
                    InfoRow(title: "Entry Price", detail: formatCurrency(stock.entryPrice))
                    InfoRow(title: "Shares Bought", detail: formatNumber(stock.shareCount))
                }

                InfoSection(title: "Account Details") {
                    InfoRow(title: "Account Used", detail: stock.accountUsed)
                    InfoRow(title: "Balance At Trade", detail: formatCurrency(stock.balanceAtTrade))
                    InfoRow(title: "Risk Percentage", detail: formatPercent(stock.riskPercentage / 100))
                }

                InfoSection(title: "Timeline") {
                    InfoRow(
                        title: "Created",
                        detail: stock.createdAt.formatted(date: .abbreviated, time: .shortened)
                    )

                    if let updatedAt = stock.updatedAt {
                        InfoRow(
                            title: "Updated",
                            detail: updatedAt.formatted(date: .abbreviated, time: .shortened)
                        )
                    }
                }
            }
            .padding()
        }
        .navigationTitle(stock.ticker.isEmpty ? "Stock Calc" : stock.ticker)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    presentSheet.toggle()
                } label: {
                    Image(systemName: "pencil")
                }
                .help("Edit Calcuation")
                .keyboardShortcut("E")
                .sheet(isPresented: $presentSheet) {
                    NewEditRiskCalc(stock: stock, isNew: false)
                }

                Button {
                    toggleAlert.toggle()
                } label: {
                    Image(systemName: "trash")
                }
                .help("Delete")
                .keyboardShortcut("D")
                .alert("Delete Calculation", isPresented: $toggleAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Yes", role: .destructive) {
                        deleteCalc()
                    }
                } message: {
                    Text("Are you sure you want to do this?")
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(stock.ticker.isEmpty ? "Stock Calculation" : stock.ticker)
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("Review reward, risk, position sizing, and account impact in one place.")
                .foregroundStyle(.secondary)
        }
    }

    private func formatCurrency(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)))
    }

    private func formatNumber(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)))
    }

    private func formatPercent(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(2)))
    }

    private func deleteCalc() {
        withAnimation {
            modelContext.delete(stock)
            try? modelContext.save()
        }
        dismiss()
    }
}

#Preview {
    StockCalcView(stock: Stock(ticker: "DAL", entryPrice: 100, riskPercentage: 1, stopLoss: 80, shareCount: 100, targetPrice: 150, accountUsed: "WeBull", balanceAtTrade: 50000, amountRisked: 100))
}
