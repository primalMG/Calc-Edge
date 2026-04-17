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
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    var updatedAt: Date?
    var calculator: ForexCalculatorType = ForexCalculatorType.pipValue

    // Core identifiers
    var pair: String = ""
    var accountCurrency: String = "USD"

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
    var marketPairRate: Decimal?
    var pipSizeOverride: Decimal?

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        updatedAt: Date? = nil,
        calculator: ForexCalculatorType = ForexCalculatorType.pipValue,
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
        marketPairRate: Decimal? = nil,
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
        self.marketPairRate = marketPairRate
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
        if calculator == .margin {
            if let lotSize {
                return lotSize * Decimal(100000)
            }
            return units
        }

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
        if calculator == .pipValue {
            // Pip Value calculator treats pip size as "points", where 10 points = 1 pip.
            return (pipSize * conversionRate) / Decimal(10)
        }
        return pipSize * conversionRate
    }

    var totalPipValue: Decimal? {
        guard let pipValuePerUnit else { return nil }

        if calculator == .pipValue {
            guard let lotSize else { return nil }
            return lotSize * pipValuePerUnit
        }

        guard let derivedUnits else { return nil }
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
              let marketRate = effectiveMarketRate,
              let quoteToAccountRate = marginQuoteToAccountRate else {
            return nil
        }

        return (derivedUnits * marketRate * quoteToAccountRate) / leverage
    }

    var derivedMarginRequiredInt: Int? {
        guard let derivedMarginRequired else { return nil }
        // Margin UI expects whole numbers; discard fractional precision.
        return Int(NSDecimalNumber(decimal: derivedMarginRequired).doubleValue)
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
        if quoteCurrency == accountCurrency {
            return Decimal(1)
        }

        if let quoteToAccountRate {
            return quoteToAccountRate
        }

        return nil
    }

    var effectiveMarketRate: Decimal? {
        if let marketPairRate {
            return marketPairRate
        }

        if let entryPrice {
            return entryPrice
        }

        return nil
    }

    var marginQuoteToAccountRate: Decimal? {
        if let effectiveQuoteToAccountRate {
            return effectiveQuoteToAccountRate
        }

        guard baseCurrency == accountCurrency,
              let marketRate = effectiveMarketRate,
              marketRate != 0 else {
            return nil
        }

        return Decimal(1) / marketRate
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
