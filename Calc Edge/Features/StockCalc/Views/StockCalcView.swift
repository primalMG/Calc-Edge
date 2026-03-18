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

    private var riskRewardRatioColor: Color {
        stock.riskRewardRatio > 1.5 ? .green : .red
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                StockCalcSection(title: "Overview") {
                    LazyVGrid(columns: statColumns, alignment: .leading, spacing: 12) {
                        StockCalcStatCard(
                            title: "Potential Profit",
                            value: formatCurrency(stock.profitTotal),
                            accentColor: .green
                        )
                        StockCalcStatCard(
                            title: "Potential Loss",
                            value: formatCurrency(stock.lossTotal),
                            accentColor: .red
                        )
                        StockCalcStatCard(
                            title: "Risk / Reward",
                            value: formatNumber(stock.riskRewardRatio),
                            accentColor: riskRewardRatioColor
                        )
                        StockCalcStatCard(
                            title: "Amount Risked",
                            value: formatCurrency(stock.amountRisked)
                        )
                    }
                }

                StockCalcSection(title: "Profit Breakdown") {
                    StockCalcRow(title: "Technical Target", detail: formatCurrency(stock.targetPrice))
                    StockCalcRow(title: "Profit Per Share", detail: formatCurrency(stock.profitDifference))
                    StockCalcRow(title: "Potential Profit", detail: formatCurrency(stock.profitTotal))
                }

                StockCalcSection(title: "Loss Breakdown") {
                    StockCalcRow(title: "Stop Loss", detail: formatCurrency(stock.stopLoss))
                    StockCalcRow(title: "Loss Per Share", detail: formatCurrency(stock.lossDiffernce))
                    StockCalcRow(title: "Potential Loss", detail: formatCurrency(stock.lossTotal))
                }

                StockCalcSection(title: "Position Details") {
                    StockCalcRow(title: "Ticker", detail: stock.ticker)
                    StockCalcRow(title: "Entry Price", detail: formatCurrency(stock.entryPrice))
                    StockCalcRow(title: "Shares Bought", detail: formatNumber(stock.shareCount))
                }

                StockCalcSection(title: "Account Details") {
                    StockCalcRow(title: "Account Used", detail: stock.accountUsed)
                    StockCalcRow(title: "Balance At Trade", detail: formatCurrency(stock.balanceAtTrade))
                    StockCalcRow(title: "Risk Percentage", detail: formatPercent(stock.riskPercentage / 100))
                }

                StockCalcSection(title: "Timeline") {
                    StockCalcRow(
                        title: "Created",
                        detail: stock.createdAt.formatted(date: .abbreviated, time: .shortened)
                    )

                    if let updatedAt = stock.updatedAt {
                        StockCalcRow(
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

private struct StockCalcSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private struct StockCalcStatCard: View {
    let title: String
    let value: String
    let accentColor: Color?

    init(title: String, value: String, accentColor: Color? = nil) {
        self.title = title
        self.value = value
        self.accentColor = accentColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(accentColor ?? .primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct StockCalcRow: View {
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .fontWeight(.medium)

            Spacer(minLength: 16)

            Text(detail)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .font(.callout)
    }
}

#Preview {
    StockCalcView(stock: Stock(ticker: "DAL", entryPrice: 100, riskPercentage: 1, stopLoss: 80, shareCount: 100, targetPrice: 150, accountUsed: "WeBull", balanceAtTrade: 50000, amountRisked: 100))
}
