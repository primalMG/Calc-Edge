import Foundation
import SwiftData

@Model
final class Trade {
    // Identification
    var tradeId: UUID = UUID()
    var openedAt: Date = Date.now
    var closedAt: Date?

    var ticker: String = ""
    var market: String?
    var account: String?
    var instrument: InstrumentType = InstrumentType.stock
    var direction: TradeDirection = TradeDirection.long

    // Strategy & thesis
    var strategyName: String?
    var setupType: String?
    var timeframe: String?
    @Attribute(.externalStorage) var thesis: String?
    var catalyst: String?
    var confidenceScore: Int = 3
    var isAPlusSetup: Bool = false

    // Entry/Exit (for simple single-leg trades)
    var shareCount: Decimal = 0
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
    @Relationship(deleteRule: .cascade, inverse: \TradeLeg.trade) var legs: [TradeLeg]? = []
    @Relationship(deleteRule: .cascade, inverse: \TradeContext.trade) var context: TradeContext?
    @Relationship(deleteRule: .cascade, inverse: \TradeReview.trade) var review: TradeReview?
    @Relationship(deleteRule: .cascade, inverse: \TradeAttachment.trade) var attachments: [TradeAttachment]? = []
    @Relationship(deleteRule: .cascade, inverse: \TradeTransaction.trade) var transactions: [TradeTransaction]? = []

    init(
        tradeId: UUID = UUID(),
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
        shareCount: Decimal = 0,
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

        self.shareCount = shareCount
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
