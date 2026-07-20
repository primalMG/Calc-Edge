//
//  Calc_EdgeApp.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 11/01/2026.
//

import SwiftUI
import SwiftData

@main
struct Calc_EdgeApp: App {
    private static let onboardingCompletionDefault: Bool = {
        #if DEBUG
        if ProcessInfo.processInfo.environment["CALC_EDGE_UI_TEST_RESET_ONBOARDING"] == "1" {
            UserDefaults.standard.removeObject(forKey: "onboarding.hasCompleted")
        }
        #endif
        return false
    }()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Account.self,
            ForexCalculation.self,
            Note.self,
            Stock.self,
            Trade.self,
            TradeAttachment.self,
            TradeContext.self,
            TradeFieldSuggestion.self,
            TradeLeg.self,
            TradeReview.self,
            TradeRuleCheck.self,
            TradeTransaction.self,
            TradeValueChangeLog.self,
            TradingRule.self,
            TradingSetup.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .private("iCloud.com.marcusgardner.Calc-Edge")
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError(
                """
                Could not create ModelContainer: \(error)
                If you recently enabled CloudKit, remove the existing app data/store once and relaunch so SwiftData can rebuild the container with the updated schema.
                """
            )
        }
    }()
    
    @AppStorage("onboarding.hasCompleted") private var hasCompletedOnboarding = Self.onboardingCompletionDefault
    @State private var initialDestination = AppStartDestination.journal
    @State private var draftTrade = Trade(ticker: "")
    @State private var draftForexCalculation = ForexCalculation(pair: "")

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                RootView(initialDestination: initialDestination)
            } else {
                OnboardingView { destination in
                    initialDestination = destination
                    hasCompletedOnboarding = true
                }
            }
        }
        .modelContainer(sharedModelContainer)
        
        #if os(macOS)
        Window("New Journal Entry", id: "new-journal") {
            NewJournalView(trade: draftTrade)
        }
        .modelContainer(sharedModelContainer)

        Window("New Forex Calculation", id: "new-forex-calc") {
            AddEditForexCalcView(calculation: draftForexCalculation, isNew: true)
        }
        .modelContainer(sharedModelContainer)
        #endif
    }
}
