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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Account.self,
            Stock.self,
            Trade.self,
            TradeAttachment.self,
            TradeContext.self,
            TradeLeg.self,
            TradeReview.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    @State private var draftTrade = Trade(ticker: "")

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(sharedModelContainer)
        
        Window("New Journal Entry", id: "new-journal") {
            NewJournalView(trade: draftTrade)
        }
        .modelContainer(sharedModelContainer)
    }
}
