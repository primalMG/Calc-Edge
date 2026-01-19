import Foundation
import SwiftData

@Model
final class TradeContext {
    var marketRegime: MarketRegime
    var vix: Decimal?
    var indexTrend: String?
    var sectorStrength: String?
    var newsDuringTrade: String?
    var timeOfDayTag: String?

    init(
        marketRegime: MarketRegime = .unknown,
        vix: Decimal? = nil,
        indexTrend: String? = nil,
        sectorStrength: String? = nil,
        newsDuringTrade: String? = nil,
        timeOfDayTag: String? = nil
    ) {
        self.marketRegime = marketRegime
        self.vix = vix
        self.indexTrend = indexTrend
        self.sectorStrength = sectorStrength
        self.newsDuringTrade = newsDuringTrade
        self.timeOfDayTag = timeOfDayTag
    }
}
