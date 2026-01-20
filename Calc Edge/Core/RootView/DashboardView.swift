//
//  DashboardView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 19/01/2026.
//

import SwiftUI

struct DashboardView: View {
    @Binding var selectedStock: Stock

    private let columns = [GridItem(.adaptive(minimum: 220), spacing: 16)]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                NavigationLink {
                    RiskCalcListView(selectedStock: $selectedStock)
                } label: {
                    DashboardCard(
                        title: "Risk Calc",
                        subtitle: "View and manage calculations",
                        systemImage: "chart.line.uptrend.xyaxis"
                    )
                }

                NavigationLink {
                    TradeJournalView()
                } label: {
                    DashboardCard(
                        title: "Trade Journal",
                        subtitle: "Track and review trades",
                        systemImage: "book"
                    )
                }

                NavigationLink {
                    NewEditRiskCalc(stock: selectedStock)
                } label: {
                    DashboardCard(
                        title: "New Calculation",
                        subtitle: "Start a fresh risk calc",
                        systemImage: "square.and.pencil"
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Dashboard")
    }
}

private struct DashboardCard: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)

            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
