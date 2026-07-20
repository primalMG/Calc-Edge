//
//  ContentView.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 11/01/2026.
//

import SwiftUI

struct RootView: View {
    @Environment(AppDataResetCoordinator.self) private var dataResetCoordinator

    @State private var selectedTab: RootTab
    @State private var selectedStock = Stock.emptyDraft
    private let initialCalculatorRoute: CalculatorRoute?

    init(initialDestination: AppStartDestination = .journal) {
        _selectedTab = State(initialValue: initialDestination.rootTab)
        initialCalculatorRoute = initialDestination.calculatorRoute
    }
    
    var body: some View {
        Group {
            if dataResetCoordinator.isResetting {
                DataResetSceneContent(phase: dataResetCoordinator.phase)
            } else {
                rootTabs
                    .id(dataResetCoordinator.resetGeneration)
                    .onDisappear(perform: dataResetCoordinator.dataBackedViewsDidDisappear)
            }
        }
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
        TabView(selection: $selectedTab) {
            TabSection("Journals") {
                Tab(RootTab.journal.title, systemImage: RootTab.journal.systemImage, value: RootTab.journal) {
                    rootTab(.journal)
                }

                Tab(RootTab.insights.title, systemImage: RootTab.insights.systemImage, value: RootTab.insights) {
                    rootTab(.insights)
                }

                Tab(RootTab.reviewCalendar.title, systemImage: RootTab.reviewCalendar.systemImage, value: RootTab.reviewCalendar) {
                    rootTab(.reviewCalendar)
                }

                Tab(RootTab.notes.title, systemImage: RootTab.notes.systemImage, value: RootTab.notes) {
                    rootTab(.notes)
                }

                Tab(RootTab.rulebook.title, systemImage: RootTab.rulebook.systemImage, value: RootTab.rulebook) {
                    rootTab(.rulebook)
                }

                Tab(RootTab.playbook.title, systemImage: RootTab.playbook.systemImage, value: RootTab.playbook) {
                    rootTab(.playbook)
                }
            }

            TabSection("Calculators") {
                Tab(RootTab.stockCalc.title, systemImage: RootTab.stockCalc.systemImage, value: RootTab.stockCalc) {
                    rootTab(.stockCalc)
                }

                Tab(RootTab.forexCalc.title, systemImage: RootTab.forexCalc.systemImage, value: RootTab.forexCalc) {
                    rootTab(.forexCalc)
                }
            }

            TabSection("Manage") {
                Tab(RootTab.accounts.title, systemImage: RootTab.accounts.systemImage, value: RootTab.accounts) {
                    rootTab(.accounts)
                }

                Tab(RootTab.suggestions.title, systemImage: RootTab.suggestions.systemImage, value: RootTab.suggestions) {
                    rootTab(.suggestions)
                }
            }

            TabSection("App") {
                Tab(RootTab.privacy.title, systemImage: RootTab.privacy.systemImage, value: RootTab.privacy) {
                    rootTab(.privacy)
                }

                Tab(RootTab.clearData.title, systemImage: RootTab.clearData.systemImage, value: RootTab.clearData) {
                    rootTab(.clearData)
                }
            }
        }
    }
    #endif

    private var iOSTabs: some View {
        TabView(selection: $selectedTab) {
            ForEach(RootTab.availableTabs) { tab in
                rootTab(tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .tag(tab)
            }
        }
        .tint(.primary)
    }

    private func rootTab(_ tab: RootTab) -> some View {
        RootTabScene(
            tab: tab,
            selectedStock: $selectedStock,
            initialCalculatorRoute: tab == .calculators ? initialCalculatorRoute : nil
        )
    }
}

#Preview {
    RootView()
        .environment(AppDataResetCoordinator())
}
