import Foundation
import SwiftData

@MainActor
enum AppDataResetService {
    static func clearAllData(in modelContext: ModelContext) throws -> Int {
        var deletedCount = 0

        deletedCount += try deleteAll(of: TradeAttachment.self, in: modelContext)
        deletedCount += try deleteAll(of: TradeContext.self, in: modelContext)
        deletedCount += try deleteAll(of: TradeLeg.self, in: modelContext)
        deletedCount += try deleteAll(of: TradeReview.self, in: modelContext)
        deletedCount += try deleteAll(of: TradeTransaction.self, in: modelContext)
        deletedCount += try deleteAll(of: TradeValueChangeLog.self, in: modelContext)
        deletedCount += try deleteAll(of: TradeRuleCheck.self, in: modelContext)
        deletedCount += try deleteAll(of: Trade.self, in: modelContext)
        deletedCount += try deleteAll(of: TradingRule.self, in: modelContext)
        deletedCount += try deleteAll(of: TradingSetup.self, in: modelContext)
        deletedCount += try deleteAll(of: TradeFieldSuggestion.self, in: modelContext)
        deletedCount += try deleteAll(of: Note.self, in: modelContext)
        deletedCount += try deleteAll(of: ForexCalculation.self, in: modelContext)
        deletedCount += try deleteAll(of: Stock.self, in: modelContext)
        deletedCount += try deleteAll(of: Account.self, in: modelContext)

        if deletedCount > 0 {
            try modelContext.save()
        }

        return deletedCount
    }

    private static func deleteAll<Model: PersistentModel>(
        of _: Model.Type,
        in modelContext: ModelContext
    ) throws -> Int {
        let models = try modelContext.fetch(FetchDescriptor<Model>())

        for model in models {
            modelContext.delete(model)
        }

        return models.count
    }
}
