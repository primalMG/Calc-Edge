import Foundation
import SwiftData

@Model
final class TradingSetup {
    var setupId: UUID = UUID()
    var name: String = ""
    var strategyName: String?
    var timeframe: String?
    var catalyst: String?
    @Attribute(.externalStorage) var criteria: String?
    @Attribute(.externalStorage) var invalidation: String?
    @Attribute(.externalStorage) var notes: String?
    var isActive: Bool = true
    var createdAt: Date = Date.now
    var updatedAt: Date = Date.now

    init(
        setupId: UUID = UUID(),
        name: String,
        strategyName: String? = nil,
        timeframe: String? = nil,
        catalyst: String? = nil,
        criteria: String? = nil,
        invalidation: String? = nil,
        notes: String? = nil,
        isActive: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.setupId = setupId
        self.name = name
        self.strategyName = strategyName
        self.timeframe = timeframe
        self.catalyst = catalyst
        self.criteria = criteria
        self.invalidation = invalidation
        self.notes = notes
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

