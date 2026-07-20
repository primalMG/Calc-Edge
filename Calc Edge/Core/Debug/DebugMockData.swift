#if DEBUG
import SwiftData
import SwiftUI

struct DebugMockDataMenu: View {
    let seed: () -> Void
    let clear: () -> Void

    var body: some View {
        Menu {
            Button(action: seed) {
                Label("Seed Mock Data", systemImage: "shippingbox.and.arrow.backward")
            }

            Button(role: .destructive, action: clear) {
                Label("Clear Mock Data", systemImage: "trash")
            }
        } label: {
            Label("Mock Data", systemImage: "shippingbox")
        }
        .help("Mock Data")
    }
}

@MainActor
enum DebugMockData {
    private static let calendar = Calendar.current

    private static let stockIDs = ids([
        "10000000-0000-0000-0000-000000000001",
        "10000000-0000-0000-0000-000000000002",
        "10000000-0000-0000-0000-000000000003",
        "10000000-0000-0000-0000-000000000004",
        "10000000-0000-0000-0000-000000000005"
    ])
    private static let forexIDs = ids([
        "20000000-0000-0000-0000-000000000001",
        "20000000-0000-0000-0000-000000000002",
        "20000000-0000-0000-0000-000000000003",
        "20000000-0000-0000-0000-000000000004"
    ])
    private static let noteIDs = ids([
        "30000000-0000-0000-0000-000000000001",
        "30000000-0000-0000-0000-000000000002",
        "30000000-0000-0000-0000-000000000003",
        "30000000-0000-0000-0000-000000000004",
        "30000000-0000-0000-0000-000000000005"
    ])
    private static let ruleIDs = ids([
        "40000000-0000-0000-0000-000000000001",
        "40000000-0000-0000-0000-000000000002",
        "40000000-0000-0000-0000-000000000003",
        "40000000-0000-0000-0000-000000000004",
        "40000000-0000-0000-0000-000000000005"
    ])
    private static let ruleTradeIDs = ids([
        "41000000-0000-0000-0000-000000000001",
        "41000000-0000-0000-0000-000000000002",
        "41000000-0000-0000-0000-000000000003",
        "41000000-0000-0000-0000-000000000004"
    ])
    private static let setupIDs = ids([
        "50000000-0000-0000-0000-000000000001",
        "50000000-0000-0000-0000-000000000002",
        "50000000-0000-0000-0000-000000000003",
        "50000000-0000-0000-0000-000000000004"
    ])
    private static let setupTradeIDs = ids([
        "51000000-0000-0000-0000-000000000001",
        "51000000-0000-0000-0000-000000000002",
        "51000000-0000-0000-0000-000000000003",
        "51000000-0000-0000-0000-000000000004",
        "51000000-0000-0000-0000-000000000005",
        "51000000-0000-0000-0000-000000000006",
        "51000000-0000-0000-0000-000000000007",
        "51000000-0000-0000-0000-000000000008"
    ])

    static func seedStocks(in context: ModelContext) throws -> Int {
        _ = try clearStocks(in: context, save: false)
        let fixtures = [
            Stock(id: stockIDs[0], createdAt: daysAgo(1), updatedAt: hoursAgo(3), ticker: "NVDA", entryPrice: 172.40, riskPercentage: 0.75, stopLoss: 168.90, shareCount: 107, targetPrice: 181.15, accountUsed: "Growth Account", balanceAtTrade: 50_000, amountRisked: 375),
            Stock(id: stockIDs[1], createdAt: daysAgo(3), updatedAt: daysAgo(2), ticker: "AAPL", entryPrice: 231.80, riskPercentage: 0.50, stopLoss: 228.60, shareCount: 78, targetPrice: 239.80, accountUsed: "ISA", balanceAtTrade: 50_000, amountRisked: 250),
            Stock(id: stockIDs[2], createdAt: daysAgo(6), ticker: "TSLA", entryPrice: 328.50, riskPercentage: 1.00, stopLoss: 319.25, shareCount: 54, targetPrice: 347.00, accountUsed: "Momentum", balanceAtTrade: 50_000, amountRisked: 500),
            Stock(id: stockIDs[3], createdAt: daysAgo(9), ticker: "AMD", entryPrice: 154.20, riskPercentage: 0.60, stopLoss: 151.70, shareCount: 120, targetPrice: 160.45, accountUsed: "Growth Account", balanceAtTrade: 50_000, amountRisked: 300),
            Stock(id: stockIDs[4], createdAt: daysAgo(14), ticker: "META", entryPrice: 612.00, riskPercentage: 0.50, stopLoss: 605.75, shareCount: 40, targetPrice: 627.60, accountUsed: "ISA", balanceAtTrade: 50_000, amountRisked: 250)
        ]
        fixtures.forEach(context.insert)
        try context.save()
        return fixtures.count
    }

    static func clearStocks(in context: ModelContext) throws -> Int {
        try clearStocks(in: context, save: true)
    }

    static func seedForex(in context: ModelContext) throws -> Int {
        _ = try clearForex(in: context, save: false)
        let fixtures = [
            ForexCalculation(id: forexIDs[0], createdAt: hoursAgo(2), updatedAt: hoursAgo(1), calculator: .positionSize, pair: "EURUSD", accountCurrency: "GBP", accountBalance: 25_000, riskPercent: 0.75, entryPrice: 1.1724, stopLossPrice: 1.1684, quoteToAccountRate: 0.745),
            ForexCalculation(id: forexIDs[1], createdAt: daysAgo(2), calculator: .riskReward, pair: "GBPJPY", accountCurrency: "GBP", entryPrice: 198.42, stopLossPrice: 197.92, takeProfitPrice: 199.67),
            ForexCalculation(id: forexIDs[2], createdAt: daysAgo(4), calculator: .pipValue, pair: "USDJPY", accountCurrency: "USD", lotSize: 0.80, quoteToAccountRate: 0.00672),
            ForexCalculation(id: forexIDs[3], createdAt: daysAgo(8), calculator: .margin, pair: "AUDUSD", accountCurrency: "USD", lotSize: 1.20, leverage: 30, marketPairRate: 0.6528)
        ]
        fixtures.forEach(context.insert)
        try context.save()
        return fixtures.count
    }

    static func clearForex(in context: ModelContext) throws -> Int {
        try clearForex(in: context, save: true)
    }

    static func seedNotes(in context: ModelContext) throws -> Int {
        _ = try clearNotes(in: context, save: false)
        let fixtures = [
            Note(noteId: noteIDs[0], title: "Weekly review — process first", body: "Best trading came from waiting for the opening range to settle. Keep risk at 0.5% until execution is consistent for two full weeks.\n\nFocus next week: fewer trades, clearer invalidation, no entries during lunch.", createdAt: daysAgo(1), updatedAt: hoursAgo(2)),
            Note(noteId: noteIDs[1], title: "NVDA earnings plan", body: "Key level: 170.00\nBull case: hold above pre-market high and reclaim VWAP.\nBear case: failed breakout with volume.\nMaximum risk: £300.", createdAt: daysAgo(2), updatedAt: daysAgo(1)),
            Note(noteId: noteIDs[2], title: "Pre-market checklist", body: "Check index trend, sector strength, scheduled news, and relative volume. Mark the entry, stop, target, and position size before the bell.", createdAt: daysAgo(5), updatedAt: daysAgo(3)),
            Note(noteId: noteIDs[3], title: "Lessons from a red day", body: "The first loss was valid. The second and third trades were attempts to make it back. Stop after two consecutive rule breaks and walk away for 20 minutes.", createdAt: daysAgo(9), updatedAt: daysAgo(6)),
            Note(noteId: noteIDs[4], title: "Books and research", body: "Review chapters on expectancy, drawdown control, and deliberate practice. Test one idea at a time rather than changing the whole process.", createdAt: daysAgo(15), updatedAt: daysAgo(10))
        ]
        fixtures.forEach(context.insert)
        try context.save()
        return fixtures.count
    }

    static func clearNotes(in context: ModelContext) throws -> Int {
        try clearNotes(in: context, save: true)
    }

    static func seedRules(in context: ModelContext) throws -> Int {
        _ = try clearRules(in: context, save: false)
        let rules = [
            TradingRule(ruleId: ruleIDs[0], title: "Define risk before entry", category: "Risk", ruleDescription: "Every trade needs a hard invalidation level and position size before the order is placed.", checklistPrompt: "Are the stop and maximum account risk defined?", updatedAt: hoursAgo(1)),
            TradingRule(ruleId: ruleIDs[1], title: "Wait for confirmation", category: "Entry", ruleDescription: "Let price confirm the thesis instead of anticipating the move.", checklistPrompt: "Has the trigger candle closed with supporting volume?", updatedAt: daysAgo(1)),
            TradingRule(ruleId: ruleIDs[2], title: "Never average down", category: "Risk", ruleDescription: "A losing position cannot be enlarged. Exit at invalidation and reassess from flat.", checklistPrompt: "Am I adding only because price moved against me?", updatedAt: daysAgo(3)),
            TradingRule(ruleId: ruleIDs[3], title: "Respect the daily stop", category: "Process", ruleDescription: "Stop trading after two rule-breaking losses or the daily loss limit is reached.", checklistPrompt: "Is the daily loss limit still intact?", updatedAt: daysAgo(6)),
            TradingRule(ruleId: ruleIDs[4], title: "No lunch-hour entries", category: "Timing", ruleDescription: "Avoid the low-liquidity period unless a pre-planned catalyst is active.", checklistPrompt: "Is this inside an approved trading window?", isActive: false, updatedAt: daysAgo(12))
        ]
        rules.forEach(context.insert)

        let outcomes: [(String, Decimal, Decimal, Decimal, Bool)] = [
            ("AAPL", 231, 237, 228, true),
            ("NVDA", 171, 179, 168, true),
            ("TSLA", 329, 324, 325, false),
            ("AMD", 154, 158, 152, true)
        ]

        for (index, outcome) in outcomes.enumerated() {
            let trade = Trade(
                tradeId: ruleTradeIDs[index],
                openedAt: daysAgo(index + 2),
                closedAt: daysAgo(index + 2),
                ticker: outcome.0,
                account: "Rulebook Demo",
                strategyName: "Rulebook Sample",
                setupType: "Confirmation Entry",
                timeframe: "Intraday",
                shareCount: 100,
                entryPrice: outcome.1,
                exitPrice: outcome.2,
                stopPrice: outcome.3
            )
            let review = TradeReview(followedPlan: outcome.4)
            review.trade = trade
            trade.review = review
            context.insert(trade)
            context.insert(review)

            for (ruleIndex, rule) in rules.prefix(3).enumerated() {
                let followed = outcome.4 || ruleIndex == 2
                let check = TradeRuleCheck(followed: followed, note: followed ? "Confirmed in review" : "Rule broken in demo trade", rule: rule, review: review)
                context.insert(check)
            }
        }

        try context.save()
        return rules.count
    }

    static func clearRules(in context: ModelContext) throws -> Int {
        try clearRules(in: context, save: true)
    }

    static func seedSetups(in context: ModelContext) throws -> Int {
        _ = try clearSetups(in: context, save: false)
        let setups = [
            TradingSetup(setupId: setupIDs[0], name: "Opening Range Breakout", strategyName: "Momentum", timeframe: "5 min", catalyst: "Relative volume", criteria: "Price holds above VWAP, the opening range forms cleanly, and breakout volume is at least 1.5× average.", invalidation: "A close back inside the range or loss of VWAP.", notes: "Best between 09:45 and 10:30. Avoid extended third pushes.", updatedAt: hoursAgo(1)),
            TradingSetup(setupId: setupIDs[1], name: "VWAP Reclaim", strategyName: "Intraday Reversal", timeframe: "5 min", catalyst: "Market alignment", criteria: "Failed breakdown, higher low, then reclaim and hold above VWAP with the index confirming.", invalidation: "Lower low beneath the reclaim pivot.", notes: "Enter on the first controlled pullback, not the initial reclaim candle.", updatedAt: daysAgo(2)),
            TradingSetup(setupId: setupIDs[2], name: "Breakout Retest", strategyName: "Trend Continuation", timeframe: "15 min", catalyst: "Sector strength", criteria: "Established level breaks on volume and retests with declining sell pressure.", invalidation: "Retest closes decisively below the breakout level.", notes: "Prefer first retest with at least 2R to the next resistance.", updatedAt: daysAgo(5)),
            TradingSetup(setupId: setupIDs[3], name: "Gap Fill", strategyName: "Mean Reversion", timeframe: "15 min", catalyst: "Overnight gap", criteria: "No fresh catalyst, opening drive stalls, and price accepts inside the prior day range.", invalidation: "New high with expanding volume.", notes: "Paused while results are reviewed.", isActive: false, updatedAt: daysAgo(11))
        ]
        setups.forEach(context.insert)

        let trades: [(String, String, String, Decimal, Decimal, Decimal, Bool)] = [
            ("NVDA", "Opening Range Breakout", "Momentum", 171, 179, 168, true),
            ("AAPL", "Opening Range Breakout", "Momentum", 231, 236, 229, true),
            ("TSLA", "Opening Range Breakout", "Momentum", 329, 325, 326, false),
            ("META", "VWAP Reclaim", "Intraday Reversal", 612, 621, 608, true),
            ("AMD", "VWAP Reclaim", "Intraday Reversal", 154, 151, 152, false),
            ("MSFT", "Breakout Retest", "Trend Continuation", 508, 516, 504, true),
            ("AMZN", "Breakout Retest", "Trend Continuation", 224, 230, 221, true),
            ("BABA", "Gap Fill", "Mean Reversion", 118, 115, 120, false)
        ]

        for (index, fixture) in trades.enumerated() {
            let trade = Trade(
                tradeId: setupTradeIDs[index],
                openedAt: daysAgo(index + 1),
                closedAt: daysAgo(index + 1),
                ticker: fixture.0,
                account: "Playbook Demo",
                strategyName: fixture.2,
                setupType: fixture.1,
                timeframe: index < 5 ? "5 min" : "15 min",
                catalyst: index < 3 ? "Relative volume" : nil,
                isAPlusSetup: fixture.6,
                shareCount: 100,
                entryPrice: fixture.3,
                exitPrice: fixture.4,
                stopPrice: fixture.5
            )
            context.insert(trade)
        }

        try context.save()
        return setups.count
    }

    static func clearSetups(in context: ModelContext) throws -> Int {
        try clearSetups(in: context, save: true)
    }

    private static func clearStocks(in context: ModelContext, save: Bool) throws -> Int {
        let records = try context.fetch(FetchDescriptor<Stock>()).filter { stockIDs.contains($0.id) }
        records.forEach(context.delete)
        if save { try context.save() }
        return records.count
    }

    private static func clearForex(in context: ModelContext, save: Bool) throws -> Int {
        let records = try context.fetch(FetchDescriptor<ForexCalculation>()).filter { forexIDs.contains($0.id) }
        records.forEach(context.delete)
        if save { try context.save() }
        return records.count
    }

    private static func clearNotes(in context: ModelContext, save: Bool) throws -> Int {
        let records = try context.fetch(FetchDescriptor<Note>()).filter { noteIDs.contains($0.noteId) }
        records.forEach(context.delete)
        if save { try context.save() }
        return records.count
    }

    private static func clearRules(in context: ModelContext, save: Bool) throws -> Int {
        let rules = try context.fetch(FetchDescriptor<TradingRule>()).filter { ruleIDs.contains($0.ruleId) }
        let trades = try context.fetch(FetchDescriptor<Trade>()).filter { ruleTradeIDs.contains($0.tradeId) }
        rules.forEach(context.delete)
        trades.forEach(context.delete)
        if save { try context.save() }
        return rules.count
    }

    private static func clearSetups(in context: ModelContext, save: Bool) throws -> Int {
        let setups = try context.fetch(FetchDescriptor<TradingSetup>()).filter { setupIDs.contains($0.setupId) }
        let trades = try context.fetch(FetchDescriptor<Trade>()).filter { setupTradeIDs.contains($0.tradeId) }
        setups.forEach(context.delete)
        trades.forEach(context.delete)
        if save { try context.save() }
        return setups.count
    }

    private static func ids(_ strings: [String]) -> [UUID] {
        strings.compactMap(UUID.init(uuidString:))
    }

    private static func daysAgo(_ value: Int) -> Date {
        calendar.date(byAdding: .day, value: -value, to: .now) ?? .now
    }

    private static func hoursAgo(_ value: Int) -> Date {
        calendar.date(byAdding: .hour, value: -value, to: .now) ?? .now
    }
}
#endif
