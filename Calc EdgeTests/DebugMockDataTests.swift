#if DEBUG
import SwiftData
import Testing
@testable import Calc_Edge

@MainActor
struct DebugMockDataTests {
    @Test func seedsAndClearsEveryFeatureWithoutTouchingUserRecords() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let userNote = Note(title: "Keep me")
        context.insert(userNote)

        #expect(try DebugMockData.seedStocks(in: context) == 5)
        #expect(try DebugMockData.seedForex(in: context) == 4)
        #expect(try DebugMockData.seedNotes(in: context) == 5)
        #expect(try DebugMockData.seedRules(in: context) == 5)
        #expect(try DebugMockData.seedSetups(in: context) == 4)

        #expect(try context.fetchCount(FetchDescriptor<Stock>()) == 5)
        #expect(try context.fetchCount(FetchDescriptor<ForexCalculation>()) == 4)
        #expect(try context.fetchCount(FetchDescriptor<Note>()) == 6)
        #expect(try context.fetchCount(FetchDescriptor<TradingRule>()) == 5)
        #expect(try context.fetchCount(FetchDescriptor<TradingSetup>()) == 4)
        #expect(try context.fetchCount(FetchDescriptor<Trade>()) == 12)

        #expect(try DebugMockData.clearStocks(in: context) == 5)
        #expect(try DebugMockData.clearForex(in: context) == 4)
        #expect(try DebugMockData.clearNotes(in: context) == 5)
        #expect(try DebugMockData.clearRules(in: context) == 5)
        #expect(try DebugMockData.clearSetups(in: context) == 4)

        #expect(try context.fetchCount(FetchDescriptor<Stock>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ForexCalculation>()) == 0)
        #expect(try context.fetch(FetchDescriptor<Note>()).map(\.title) == ["Keep me"])
        #expect(try context.fetchCount(FetchDescriptor<TradingRule>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<TradingSetup>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Trade>()) == 0)
    }

    private func makeContainer() throws -> ModelContainer {
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
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
#endif
