import Foundation
import SwiftData

@Model
final class TradeLeg {
    var symbol: String?
    var legInstrument: InstrumentType
    var quantity: Decimal

    var entryPrice: Decimal?
    var exitPrice: Decimal?

    // Options specifics (only filled when legInstrument == .option)
    var optionExpiration: Date?
    var optionStrike: Decimal?
    var optionType: String?

    init(
        symbol: String? = nil,
        legInstrument: InstrumentType = .stock,
        quantity: Decimal = 0,
        entryPrice: Decimal? = nil,
        exitPrice: Decimal? = nil,
        optionExpiration: Date? = nil,
        optionStrike: Decimal? = nil,
        optionType: String? = nil
    ) {
        self.symbol = symbol
        self.legInstrument = legInstrument
        self.quantity = quantity
        self.entryPrice = entryPrice
        self.exitPrice = exitPrice
        self.optionExpiration = optionExpiration
        self.optionStrike = optionStrike
        self.optionType = optionType
    }
}
