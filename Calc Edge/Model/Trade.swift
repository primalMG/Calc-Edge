import Foundation
import SwiftData

@Model
final class Trade {
    // Identification
    @Attribute(.unique) var tradeId: String
    var openedAt: Date
    var closedAt: Date?

    var ticker: String
    var market: String?
    var account: String?
    var instrument: InstrumentType
    var direction: TradeDirection

    // Strategy & thesis
    var strategyName: String?
    var setupType: String?
    var timeframe: String?
    @Attribute(.externalStorage) var thesis: String?
    var catalyst: String?
    var confidenceScore: Int
    var isAPlusSetup: Bool

    // Entry/Exit (for simple single-leg trades)
    var entryPrice: Decimal?
    var exitPrice: Decimal?

    // Risk definition (works for stocks/options; legs can override if needed)
    var stopPrice: Decimal?
    var targetPrice: Decimal?

    /// Absolute planned risk in account currency (e.g. GBP)
    var plannedRiskAmount: Decimal?

    /// Planned account risk % (e.g. 0.5% -> store as 0.5)
    var plannedRiskPercent: Decimal?

    /// Execution costs
    var commissions: Decimal?
    var slippage: Decimal?

    // Excursions (optional but powerful)
    var mae: Decimal?
    var mfe: Decimal?

    // Exit metadata
    var exitReason: ExitReason?

    // Relationships
    @Relationship(deleteRule: .cascade) var legs: [TradeLeg] = []
    @Relationship(deleteRule: .cascade) var context: TradeContext?
    @Relationship(deleteRule: .cascade) var review: TradeReview?
    @Relationship(deleteRule: .cascade) var attachments: [TradeAttachment] = []

    init(
        tradeId: String = UUID().uuidString,
        openedAt: Date = .now,
        closedAt: Date? = nil,
        ticker: String,
        market: String? = nil,
        account: String? = nil,
        instrument: InstrumentType = .stock,
        direction: TradeDirection = .long,
        strategyName: String? = nil,
        setupType: String? = nil,
        timeframe: String? = nil,
        thesis: String? = nil,
        catalyst: String? = nil,
        confidenceScore: Int = 3,
        isAPlusSetup: Bool = false,
        entryPrice: Decimal? = nil,
        exitPrice: Decimal? = nil,
        stopPrice: Decimal? = nil,
        targetPrice: Decimal? = nil,
        plannedRiskAmount: Decimal? = nil,
        plannedRiskPercent: Decimal? = nil,
        commissions: Decimal? = nil,
        slippage: Decimal? = nil,
        mae: Decimal? = nil,
        mfe: Decimal? = nil,
        exitReason: ExitReason? = nil
    ) {
        self.tradeId = tradeId
        self.openedAt = openedAt
        self.closedAt = closedAt

        self.ticker = ticker.uppercased()
        self.market = market
        self.account = account
        self.instrument = instrument
        self.direction = direction

        self.strategyName = strategyName
        self.setupType = setupType
        self.timeframe = timeframe
        self.thesis = thesis
        self.catalyst = catalyst
        self.confidenceScore = max(1, min(5, confidenceScore))
        self.isAPlusSetup = isAPlusSetup

        self.entryPrice = entryPrice
        self.exitPrice = exitPrice
        self.stopPrice = stopPrice
        self.targetPrice = targetPrice

        self.plannedRiskAmount = plannedRiskAmount
        self.plannedRiskPercent = plannedRiskPercent

        self.commissions = commissions
        self.slippage = slippage
        self.mae = mae
        self.mfe = mfe

        self.exitReason = exitReason
    }
}
