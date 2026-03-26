//
//  DashboardView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 19/01/2026.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    private let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    @Query(sort: \Stock.createdAt, order: .reverse) private var recentStockCalcs: [Stock]
    @Query(sort: \Trade.openedAt, order: .reverse) private var recentTrades: [Trade]
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
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                NavigationLink {
                    RiskCalcListView(selectedStock: $selectedStock)
                } label: {
                    DashboardCard(
                        title: "Stock Calc",
                        subtitle: "View and manage calculations",
                        systemImage: "chart.line.uptrend.xyaxis",
                        recentTitle: "Recent Calcs",
                        recentItems: recentStockItems
                    )
                }

                NavigationLink {
                    TradeJournalView()
                } label: {
                    DashboardCard(
                        title: "Trade Journal",
                        subtitle: "Track and review trades",
                        systemImage: "book",
                        recentTitle: "Recent Entries",
                        recentItems: recentTradeItems
                    )
                }

//                NavigationLink {
//                    ForexCalcView()
//                } label: {
//                    DashboardCard(
//                        title: "Forex Calc",
//                        subtitle: "Plan FX positions",
//                        systemImage: "dollarsign.circle",
//                        recentTitle: "Updates",
//                        recentItems: ["Coming soon"]
//                    )
//                }

                NavigationLink {
                    JournalInsightsView()
                } label: {
                    DashboardCard(
                        title: "Journal Insights",
                        subtitle: "Explore trade-based performance insights",
                        systemImage: "sparkles",
                        recentTitle: "Status",
                        recentItems: ["Insights ready"]
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }

    private var recentStockItems: [String] {
        let items = recentStockCalcs.prefix(3).map { stock in
            "\(stock.ticker) • \(stock.createdAt.formatted(date: .abbreviated, time: .omitted))"
        }
        return items.isEmpty ? ["No recent calculations"] : items
    }

    private var recentTradeItems: [String] {
        let items = recentTrades.prefix(3).map { trade in
            "\(trade.ticker) • \(trade.openedAt.formatted(date: .abbreviated, time: .omitted))"
        }
        return items.isEmpty ? ["No recent journal entries"] : items
    }
}

private struct DashboardCard: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let recentTitle: String
    let recentItems: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title2)

                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                Text(recentTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(recentItems, id: \.self) { item in
                    Text(item)
                        .font(.callout)
                        .foregroundStyle(.primary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .frame(minHeight: 280)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 4)
    }
}
