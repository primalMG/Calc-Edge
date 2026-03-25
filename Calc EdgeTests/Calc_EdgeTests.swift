//
//  Calc_EdgeTests.swift
//  Calc EdgeTests
//
//  Created by Marcus Gardner on 11/01/2026.
//

import Foundation
import Testing
@testable import Calc_Edge

struct Calc_EdgeTests {

    @Test func journalAnalyticsCalculatesCoreMetrics() async throws {
        let trades = makeAnalyticsFixtureTrades()
        let insights = TradeInsightsCalculator(trades: trades, minSampleSize: 2).calculate()

        #expect(insights.totalTrades == 5)
        #expect(insights.closedTrades == 5)
        #expect(insights.pricedTrades == 5)
        #expect(insights.riskDefinedTrades == 5)

        #expect(isClose(insights.winRate, 0.6))
        #expect(isClose(insights.averageWinner, 2.0))
        #expect(isClose(insights.averageLoser, -1.75))
        #expect(isClose(insights.expectancy, 0.5))
        #expect(isClose(insights.profitFactor, 6.0 / 3.5))
    }

    @Test func journalAnalyticsBuildsSetupAndBreakdownViews() async throws {
        let trades = makeAnalyticsFixtureTrades()
        let insights = TradeInsightsCalculator(trades: trades, minSampleSize: 2).calculate()

        #expect(insights.bestSetup?.label == "Breakout")
        #expect(insights.worstSetup?.label == "Reversal")

        #expect(insights.performanceByInstrument.map(\.label) == ["Future", "Stock", "Forex"])
        #expect(insights.performanceByDirection.map(\.label) == ["Short", "Long"])
        #expect(insights.performanceByAccount.map(\.label) == ["Live", "Sim"])
        #expect(isClose(insights.performanceByAccount.first?.expectancy, 2.0 / 3.0))
        #expect(isClose(insights.performanceByAccount.last?.expectancy, 0.25))
    }

    private func makeAnalyticsFixtureTrades() -> [Trade] {
        [
            makeTrade(
                ticker: "AAPL",
                account: "Sim",
                instrument: .stock,
                direction: .long,
                setupType: "Breakout",
                entryPrice: 100,
                exitPrice: 110,
                stopPrice: 95,
                openedAt: .init(timeIntervalSince1970: 0),
                closedAt: .init(timeIntervalSince1970: 86_400)
            ),
            makeTrade(
                ticker: "MSFT",
                account: "Sim",
                instrument: .stock,
                direction: .long,
                setupType: "Breakout",
                entryPrice: 50,
                exitPrice: 47,
                stopPrice: 48,
                openedAt: .init(timeIntervalSince1970: 86_400),
                closedAt: .init(timeIntervalSince1970: 172_800)
            ),
            makeTrade(
                ticker: "EURUSD",
                account: "Live",
                instrument: .forex,
                direction: .short,
                setupType: "Reversal",
                entryPrice: 100,
                exitPrice: 102,
                stopPrice: 101,
                openedAt: .init(timeIntervalSince1970: 172_800),
                closedAt: .init(timeIntervalSince1970: 176_400)
            ),
            makeTrade(
                ticker: "GBPUSD",
                account: "Live",
                instrument: .forex,
                direction: .short,
                setupType: "Reversal",
                entryPrice: 80,
                exitPrice: 76,
                stopPrice: 82,
                openedAt: .init(timeIntervalSince1970: 180_000),
                closedAt: .init(timeIntervalSince1970: 187_200)
            ),
            makeTrade(
                ticker: "NQ",
                account: "Live",
                instrument: .future,
                direction: .short,
                setupType: "Breakout",
                entryPrice: 200,
                exitPrice: 190,
                stopPrice: 205,
                openedAt: .init(timeIntervalSince1970: 190_800),
                closedAt: .init(timeIntervalSince1970: 196_200)
            )
        ]
    }

    private func makeTrade(
        ticker: String,
        account: String,
        instrument: InstrumentType,
        direction: TradeDirection,
        setupType: String,
        entryPrice: Decimal,
        exitPrice: Decimal,
        stopPrice: Decimal,
        openedAt: Date,
        closedAt: Date
    ) -> Trade {
        Trade(
            openedAt: openedAt,
            closedAt: closedAt,
            ticker: ticker,
            account: account,
            instrument: instrument,
            direction: direction,
            setupType: setupType,
            entryPrice: entryPrice,
            exitPrice: exitPrice,
            stopPrice: stopPrice
        )
    }

    private func isClose(_ lhs: Double?, _ rhs: Double, tolerance: Double = 0.0001) -> Bool {
        guard let lhs else { return false }
        return abs(lhs - rhs) < tolerance
    }
}
