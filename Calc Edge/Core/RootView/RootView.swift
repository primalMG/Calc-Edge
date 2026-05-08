//
//  ContentView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 11/01/2026.
//

import SwiftUI

struct RootView: View {
    @State private var selectedStock = Stock.emptyDraft
    
    var body: some View {
        rootTabs
    }

    @ViewBuilder
    private var rootTabs: some View {
        #if os(macOS)
        macOSTabs
            .tabViewStyle(.sidebarAdaptable)
        #else
        iOSTabs
        
        #endif
    }

    #if os(macOS)
    private var macOSTabs: some View {
        TabView {
            Tab(RootTab.dashboard.title, systemImage: RootTab.dashboard.systemImage) {
                rootTab(.dashboard)
            }

            TabSection("Journals") {
                Tab(RootTab.journal.title, systemImage: RootTab.journal.systemImage) {
                    rootTab(.journal)
                }

                Tab(RootTab.insights.title, systemImage: RootTab.insights.systemImage) {
                    rootTab(.insights)
                }

                Tab(RootTab.notes.title, systemImage: RootTab.notes.systemImage) {
                    rootTab(.notes)
                }
            }

            TabSection("Calculators") {
                Tab(RootTab.stockCalc.title, systemImage: RootTab.stockCalc.systemImage) {
                    rootTab(.stockCalc)
                }

                Tab(RootTab.forexCalc.title, systemImage: RootTab.forexCalc.systemImage) {
                    rootTab(.forexCalc)
                }
            }

            TabSection("Manage") {
                Tab(RootTab.accounts.title, systemImage: RootTab.accounts.systemImage) {
                    rootTab(.accounts)
                }

                Tab(RootTab.suggestions.title, systemImage: RootTab.suggestions.systemImage) {
                    rootTab(.suggestions)
                }
            }
        }
    }
    #endif

    private var iOSTabs: some View {
        TabView {
            ForEach(RootTab.availableTabs) { tab in
                rootTab(tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
            }
        }
        .tint(.primary)
    }

    private func rootTab(_ tab: RootTab) -> some View {
        RootTabScene(
            tab: tab,
            selectedStock: $selectedStock
        )
    }
}

#Preview {
    RootView()
}
