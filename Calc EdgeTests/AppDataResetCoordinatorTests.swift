import SwiftData
import Testing
@testable import Calc_Edge

@MainActor
struct AppDataResetCoordinatorTests {
    @Test func resetWaitsForModelBackedViewsBeforeDeletingRecords() async throws {
        let container = try makeContainer()
        let modelContext = container.mainContext
        let trade = Trade(ticker: "AAPL")
        let calculation = ForexCalculation(calculator: .positionSize, pair: "EURUSD")

        modelContext.insert(trade)
        modelContext.insert(calculation)
        try modelContext.save()

        let coordinator = AppDataResetCoordinator()
        coordinator.clearAllData(in: modelContext)

        #expect(coordinator.phase == .preparing)
        #expect(try modelContext.fetch(FetchDescriptor<Trade>()).count == 1)
        #expect(try modelContext.fetch(FetchDescriptor<ForexCalculation>()).count == 1)

        coordinator.dataBackedViewsDidDisappear()

        while coordinator.isResetting {
            await Task.yield()
        }

        #expect(try modelContext.fetch(FetchDescriptor<Trade>()).isEmpty)
        #expect(try modelContext.fetch(FetchDescriptor<ForexCalculation>()).isEmpty)

        guard case .success(let deletedCount) = coordinator.outcome?.result else {
            Issue.record("Expected a successful reset outcome")
            return
        }
        #expect(deletedCount == 2)

        withExtendedLifetime((trade, calculation)) { }
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
