//
//  ForexCalculation.swift
//  Calc Edge
//
//  Created by Marcus Gardner on 03/02/2026.
//

import Foundation
import SwiftData

@Model
final class ForexCalculation {
    var id: UUID
    var createdAt: Date
    var updatedAt: Date?
    var calculator: ForexCalculatorType

    // Core identifiers
    var pair: String
    var accountCurrency: String

    // Account inputs
    var accountBalance: Decimal?
    var riskPercent: Decimal?
    var riskAmount: Decimal?

    // Trade inputs
    var entryPrice: Decimal?
    var stopLossPrice: Decimal?
    var stopLossPips: Decimal?
    var takeProfitPrice: Decimal?
    var takeProfitPips: Decimal?

    // Size inputs
    var lotSize: Decimal?
    var units: Decimal?

    // Conversion & margin inputs
    var leverage: Decimal?
    var quoteToAccountRate: Decimal?
    var pipSizeOverride: Decimal?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date? = nil,
        calculator: ForexCalculatorType = .pipValue,
        pair: String,
        accountCurrency: String = "USD",
        accountBalance: Decimal? = nil,
        riskPercent: Decimal? = nil,
        riskAmount: Decimal? = nil,
        entryPrice: Decimal? = nil,
        stopLossPrice: Decimal? = nil,
        stopLossPips: Decimal? = nil,
        takeProfitPrice: Decimal? = nil,
        takeProfitPips: Decimal? = nil,
        lotSize: Decimal? = nil,
        units: Decimal? = nil,
        leverage: Decimal? = nil,
        quoteToAccountRate: Decimal? = nil,
        pipSizeOverride: Decimal? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.calculator = calculator
        self.pair = ForexCalculation.normalizePair(pair)
        self.accountCurrency = accountCurrency.uppercased()
        self.accountBalance = accountBalance
        self.riskPercent = riskPercent
        self.riskAmount = riskAmount
        self.entryPrice = entryPrice
        self.stopLossPrice = stopLossPrice
        self.stopLossPips = stopLossPips
        self.takeProfitPrice = takeProfitPrice
        self.takeProfitPips = takeProfitPips
        self.lotSize = lotSize
        self.units = units
        self.leverage = leverage
        self.quoteToAccountRate = quoteToAccountRate
        self.pipSizeOverride = pipSizeOverride
    }

    var normalizedPair: String {
        ForexCalculation.normalizePair(pair)
    }

    var baseCurrency: String? {
        guard normalizedPair.count >= 6 else { return nil }
        return String(normalizedPair.prefix(3))
    }

    var quoteCurrency: String? {
        guard normalizedPair.count >= 6 else { return nil }
        return String(normalizedPair.suffix(3))
    }

    var pipSize: Decimal {
        if let pipSizeOverride {
            return pipSizeOverride
        }
        if quoteCurrency == "JPY" {
            return Decimal(0.01)
        }
        return Decimal(0.0001)
    }

    var derivedUnits: Decimal? {
        if let units {
            return units
        }
        guard let lotSize else { return nil }
        return lotSize * Decimal(100000)
    }

    var derivedRiskAmount: Decimal? {
        if let accountBalance, let riskPercent {
            let hundred = Decimal(100)
            return accountBalance * (riskPercent / hundred)
        }

        return riskAmount
    }

    var derivedStopLossPips: Decimal? {
        if let stopLossPips {
            return stopLossPips
        }
        guard let entryPrice, let stopLossPrice, pipSize != 0 else { return nil }
        let distance = abs(entryPrice - stopLossPrice)
        return distance / pipSize
    }

    var derivedTakeProfitPips: Decimal? {
        if let takeProfitPips {
            return takeProfitPips
        }
        guard let entryPrice, let takeProfitPrice, pipSize != 0 else { return nil }
        let distance = abs(takeProfitPrice - entryPrice)
        return distance / pipSize
    }

    var pipValuePerUnit: Decimal? {
        guard let conversionRate = effectiveQuoteToAccountRate else { return nil }
        return pipSize * conversionRate
    }

    var totalPipValue: Decimal? {
        guard let derivedUnits, let pipValuePerUnit else { return nil }
        return derivedUnits * pipValuePerUnit
    }

    var derivedPositionSizeUnits: Decimal? {
        guard let riskAmount = derivedRiskAmount,
              let stopLossPips = derivedStopLossPips,
              stopLossPips != 0,
              let pipValuePerUnit else {
            return nil
        }

        return riskAmount / (stopLossPips * pipValuePerUnit)
    }

    var derivedMarginRequired: Decimal? {
        guard let leverage, leverage != 0,
              let derivedUnits,
              let entryPrice else {
            return nil
        }

        return (derivedUnits * entryPrice) / leverage
    }

    var derivedRiskRewardRatio: Decimal? {
        guard let stopLossPips = derivedStopLossPips,
              let takeProfitPips = derivedTakeProfitPips,
              stopLossPips != 0 else {
            return nil
        }

        return takeProfitPips / stopLossPips
    }

    var effectiveQuoteToAccountRate: Decimal? {
        if let quoteToAccountRate {
            return quoteToAccountRate
        }

        if quoteCurrency == accountCurrency {
            return Decimal(1)
        }

        return nil
    }

    static var emptyDraft: ForexCalculation {
        ForexCalculation(pair: "")
    }

    private static func normalizePair(_ pair: String) -> String {
        pair
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "/", with: "")
    }
}
