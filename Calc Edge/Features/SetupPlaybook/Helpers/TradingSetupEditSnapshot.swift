import Foundation

struct TradingSetupEditSnapshot: Equatable {
    let name: String
    let strategyName: String?
    let timeframe: String?
    let catalyst: String?
    let criteria: String?
    let invalidation: String?
    let notes: String?
    let isActive: Bool

    init(setup: TradingSetup) {
        name = setup.name
        strategyName = setup.strategyName
        timeframe = setup.timeframe
        catalyst = setup.catalyst
        criteria = setup.criteria
        invalidation = setup.invalidation
        notes = setup.notes
        isActive = setup.isActive
    }
}
