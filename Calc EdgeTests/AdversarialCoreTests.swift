import Foundation
import Testing
@testable import Calc_Edge

@MainActor
struct AdversarialCoreTests {
    @Test func positionSummaryIsChronologicalAndCannotBeOversold() {
        let transactions = [
            TradeTransaction(date: date(3), action: .sell, quantity: 50, price: 120),
            TradeTransaction(date: date(1), action: .buy, quantity: 10, price: 100, fees: 2),
            TradeTransaction(date: date(2), action: .add, quantity: 5, price: 110, fees: 1)
        ]

        let summary = TradePositionSummary(transactions: transactions)

        #expect(summary.currentShareCount == 0)
        #expect(summary.averagePrice == nil)
        #expect(summary.costBasis == 0)
        #expect(summary.totalFees == 3)
    }

    @Test func positionSummaryIgnoresCorruptNegativePositionData() {
        let transactions = [
            TradeTransaction(action: .buy, quantity: -10, price: 100, fees: -5),
            TradeTransaction(action: .buy, quantity: 2, price: -100, fees: 4),
            TradeTransaction(action: .sell, quantity: -20, price: 100),
            TradeTransaction(action: .buy, quantity: 3, price: 10, fees: 1)
        ]

        let summary = TradePositionSummary(
            transactions: transactions,
            initialQuantity: -100,
            initialAveragePrice: -50
        )

        #expect(summary.currentShareCount == 3)
        #expect(summary.costBasis == 31)
        #expect(summary.averagePrice == Decimal(31) / Decimal(3))
        #expect(summary.totalFees == 5)
    }

    @Test func positionSummaryHandlesLargeHistoriesWithoutStateDrift() {
        let transactions = (0..<10_000).map { index in
            TradeTransaction(
                date: date(index),
                action: index.isMultiple(of: 2) ? .buy : .sell,
                quantity: 1,
                price: 100
            )
        }

        let summary = TradePositionSummary(transactions: transactions)

        #expect(summary.currentShareCount == 0)
        #expect(summary.costBasis == 0)
        #expect(summary.totalFees == 0)
    }

    @Test func realizedProfitUsesOnlyOpeningQuantityAfterFullTransactionClose() {
        let long = Trade(
            openedAt: date(0),
            closedAt: date(2),
            ticker: "LONG",
            direction: .long,
            shareCount: 10,
            entryPrice: 100,
            exitPrice: 110
        )
        long.transactions = [
            TradeTransaction(date: date(0), action: .buy, quantity: 10, price: 100),
            TradeTransaction(date: date(1), action: .sell, quantity: 10, price: 110)
        ]
        let short = Trade(
            openedAt: date(0),
            closedAt: date(2),
            ticker: "SHORT",
            direction: .short,
            shareCount: 10,
            entryPrice: 100,
            exitPrice: 90
        )
        short.transactions = [
            TradeTransaction(date: date(0), action: .sell, quantity: 10, price: 100),
            TradeTransaction(date: date(1), action: .buy, quantity: 10, price: 90)
        ]

        #expect(long.currentShareCount == 0)
        #expect(short.currentShareCount == 0)
        #expect(long.totalProfitLoss == 100)
        #expect(short.totalProfitLoss == 100)
    }

    @Test func positionSummaryAppliesFeesAndPartialClosesWithoutChangingAverageCost() {
        let summary = TradePositionSummary(
            transactions: [
                TradeTransaction(date: date(0), action: .fee, quantity: 0, price: 0, fees: 5),
                TradeTransaction(date: date(1), action: .trim, quantity: 4, price: 120, fees: 2)
            ],
            initialQuantity: 10,
            initialAveragePrice: 100
        )

        #expect(summary.currentShareCount == 6)
        #expect(summary.costBasis == 603)
        #expect(summary.averagePrice == 100.5)
        #expect(summary.totalFees == 7)
    }

    @Test func forexNormalizesCommonPairSeparatorsAndCalculatesStandardLotPipValue() {
        let calculation = ForexCalculation(
            calculator: .pipValue,
            pair: " eur-usd ",
            accountCurrency: " usd ",
            lotSize: 1
        )

        #expect(calculation.normalizedPair == "EURUSD")
        #expect(calculation.baseCurrency == "EUR")
        #expect(calculation.quoteCurrency == "USD")
        #expect(calculation.derivedUnits == 100_000)
        #expect(calculation.totalPipValue == 10)
    }

    @Test func forexRejectsMalformedPairsAndNonPositiveDivisors() {
        let malformedPair = ForexCalculation(pair: "EURUSDX", lotSize: 1)
        let invalidPip = ForexCalculation(
            calculator: .positionSize,
            pair: "EURUSD",
            accountBalance: 10_000,
            riskPercent: 1,
            stopLossPips: 10,
            pipSizeOverride: -0.0001
        )
        let invalidMargin = ForexCalculation(
            calculator: .margin,
            pair: "EURUSD",
            units: 100_000,
            leverage: -30,
            marketPairRate: 1.2
        )

        #expect(malformedPair.baseCurrency == nil)
        #expect(malformedPair.quoteCurrency == nil)
        #expect(malformedPair.totalPipValue == nil)
        #expect(invalidPip.derivedPositionSizeUnits == nil)
        #expect(invalidMargin.derivedMarginRequired == nil)
    }

    @Test func forexRejectsNegativeRiskAndSizeInputsButAllowsZero() {
        let negativeRisk = ForexCalculation(
            calculator: .positionSize,
            pair: "EURUSD",
            accountBalance: 10_000,
            riskPercent: -1,
            stopLossPips: 10
        )
        let negativeSize = ForexCalculation(
            calculator: .margin,
            pair: "EURUSD",
            units: -1,
            leverage: 30,
            marketPairRate: 1.2
        )
        let zeroRisk = ForexCalculation(
            calculator: .positionSize,
            pair: "EURUSD",
            accountBalance: 10_000,
            riskPercent: 0,
            stopLossPips: 10
        )

        #expect(negativeRisk.derivedRiskAmount == nil)
        #expect(negativeSize.derivedMarginRequired == nil)
        #expect(zeroRisk.derivedRiskAmount == 0)
        #expect(zeroRisk.derivedPositionSizeUnits == 0)
    }

    @Test func forexDerivesRiskDistanceConversionAndRewardRatio() {
        let calculation = ForexCalculation(
            calculator: .positionSize,
            pair: "USD/JPY",
            accountCurrency: "GBP",
            accountBalance: 20_000,
            riskPercent: 2,
            entryPrice: 150,
            stopLossPrice: 149.5,
            takeProfitPrice: 151,
            quoteToAccountRate: 0.005
        )

        #expect(calculation.pipSize == 0.01)
        #expect(calculation.derivedRiskAmount == 400)
        #expect(calculation.derivedStopLossPips == 50)
        #expect(calculation.derivedTakeProfitPips == 100)
        #expect(calculation.derivedRiskRewardRatio == 2)
        #expect(calculation.derivedPositionSizeUnits == 160_000)
    }

    @Test func forexMarginConvertsThroughBaseCurrencyAndTruncatesDisplayValue() {
        let calculation = ForexCalculation(
            calculator: .margin,
            pair: "EURUSD",
            accountCurrency: "EUR",
            units: 120_010,
            leverage: 30,
            marketPairRate: 1.2
        )

        #expect(calculation.effectiveQuoteToAccountRate == nil)
        #expect(calculation.marginQuoteToAccountRate == Decimal(1) / Decimal(string: "1.2")!)
        #expect((calculation.derivedMarginRequired ?? 0) > Decimal(string: "4000.33")!)
        #expect((calculation.derivedMarginRequired ?? 0) < Decimal(string: "4000.34")!)
        #expect(calculation.derivedMarginRequiredInt == 4_000)
    }

    @Test func analyticsExcludesInvalidRiskGeometryAndBackwardsDurations() {
        let valid = trade(
            ticker: "GOOD",
            entry: 100,
            exit: 110,
            stop: 95,
            openedAt: date(0),
            closedAt: date(100)
        )
        let zeroRisk = trade(
            ticker: "ZERO",
            entry: 100,
            exit: 110,
            stop: 100,
            openedAt: date(200),
            closedAt: date(100)
        )
        let wrongSideStop = trade(
            ticker: "WRONG",
            entry: 100,
            exit: 90,
            stop: 105,
            openedAt: date(0),
            closedAt: date(50)
        )

        let insights = TradeInsightsCalculator(trades: [valid, zeroRisk, wrongSideStop]).calculate()

        #expect(insights.closedTrades == 3)
        #expect(insights.pricedTrades == 3)
        #expect(insights.riskDefinedTrades == 1)
        #expect(insights.expectancy == 2)
        #expect(insights.averageHoldTime == 75)
    }

    @Test func analyticsSampleThresholdIsInclusiveAndTieOrderingIsStable() {
        let trades = [
            trade(ticker: "B", instrument: .stock, entry: 100, exit: 110, stop: 95),
            trade(ticker: "A", instrument: .stock, entry: 100, exit: 110, stop: 95),
            trade(ticker: "D", instrument: .forex, entry: 100, exit: 110, stop: 95),
            trade(ticker: "C", instrument: .forex, entry: 100, exit: 110, stop: 95)
        ]

        let inclusive = TradeInsightsCalculator(trades: trades, minSampleSize: 2).calculate()
        let exclusive = TradeInsightsCalculator(trades: trades, minSampleSize: 3).calculate()

        #expect(inclusive.performanceByInstrument.map(\.label) == ["Forex", "Stock"])
        #expect(exclusive.performanceByInstrument.isEmpty)
    }

    @Test func analyticsReturnsAbsenceInsteadOfInventedZerosForEmptyData() {
        let insights = TradeInsightsCalculator(trades: []).calculate()

        #expect(insights.totalTrades == 0)
        #expect(insights.winRate == nil)
        #expect(insights.expectancy == nil)
        #expect(insights.profitFactor == nil)
        #expect(insights.averageHoldTime == nil)
        #expect(insights.reviewCoverage == nil)
        #expect(insights.performanceByInstrument.isEmpty)
    }

    private func trade(
        ticker: String,
        instrument: InstrumentType = .stock,
        direction: TradeDirection = .long,
        entry: Decimal,
        exit: Decimal,
        stop: Decimal,
        openedAt: Date = Date(timeIntervalSince1970: 0),
        closedAt: Date = Date(timeIntervalSince1970: 100)
    ) -> Trade {
        Trade(
            openedAt: openedAt,
            closedAt: closedAt,
            ticker: ticker,
            instrument: instrument,
            direction: direction,
            entryPrice: entry,
            exitPrice: exit,
            stopPrice: stop
        )
    }

    private func date(_ seconds: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(seconds))
    }
}
