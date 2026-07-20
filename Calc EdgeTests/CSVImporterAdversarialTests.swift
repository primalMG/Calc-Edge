import Foundation
import Testing
@testable import Calc_Edge

@MainActor
struct CSVImporterAdversarialTests {
    @Test func rejectsHeaderOnlyAndEntirelyMalformedFilesMeaningfully() throws {
        let headerOnly = try temporaryCSV("Date,Ticker,Action,Quantity,Price\n")
        let malformed = try temporaryCSV(
            """
            Date,Ticker,Action,Quantity,Price
            not-a-date,AAPL,Buy,1,100
            2026-01-01,MSFT,Buy,0,100
            2026-01-01,TSLA,Sell,-1,200
            """
        )
        defer {
            try? FileManager.default.removeItem(at: headerOnly)
            try? FileManager.default.removeItem(at: malformed)
        }

        #expect(throws: JournalCSVImportError.noRows) {
            try JournalCSVImporter().importTrades(from: headerOnly)
        }
        #expect(throws: JournalCSVImportError.noImportableRows) {
            try JournalCSVImporter().importTrades(from: malformed)
        }
    }

    @Test func skipsMalformedRowsWithoutPoisoningValidRows() throws {
        let url = try temporaryCSV(
            """
            Date,Ticker,Action,Quantity,Price
            broken,AAPL,Buy,1,100
            2026-01-02,MSFT,Buy,2,250
            2026-01-03,TSLA,Sell,1,-200
            """
        )
        defer { try? FileManager.default.removeItem(at: url) }

        let trades = try JournalCSVImporter().importTrades(from: url)
        let trade = try #require(trades.first)

        #expect(trades.count == 1)
        #expect(trade.ticker == "MSFT")
        #expect(trade.shareCount == 2)
        #expect(trade.entryPrice == 250)
    }

    @Test func enforcesFileSizeAndRowCountResourceLimits() throws {
        let url = try temporaryCSV(
            """
            Date,Ticker,Action,Quantity,Price
            2026-01-01,AAPL,Buy,1,100
            2026-01-02,MSFT,Buy,1,200
            """
        )
        defer { try? FileManager.default.removeItem(at: url) }

        do {
            _ = try JournalCSVImporter(maximumFileSizeBytes: 32).importTrades(from: url)
            Issue.record("Expected the file-size limit to reject the import")
        } catch JournalCSVImportError.fileTooLarge(let maximumBytes) {
            #expect(maximumBytes == 32)
        }

        do {
            _ = try JournalCSVImporter(maximumRowCount: 1).importTrades(from: url)
            Issue.record("Expected the row-count limit to reject the import")
        } catch JournalCSVImportError.tooManyRows(let maximum) {
            #expect(maximum == 1)
        }
    }

    @Test func groupingSeparatesAccountsAndNormalizesIdentityFields() {
        let first = importedTrade(ticker: " aapl ", account: " Live ", quantity: 1, date: date(0))
        let second = importedTrade(ticker: "AAPL", account: "live", quantity: 2, date: date(1))
        let otherAccount = importedTrade(ticker: "AAPL", account: "Sim", quantity: 4, date: date(2))

        let grouped = JournalCSVImporter.groupedByMatchingTickers([first, second, otherAccount])

        #expect(grouped.count == 2)
        #expect(grouped.map(\.currentShareCount).sorted() == [3, 4])
    }

    @Test func groupingPreservesSourceOrderForEqualTimestamps() {
        let buy = importedTrade(ticker: "AAPL", account: nil, quantity: 10, date: date(0), action: .buy)
        let sell = importedTrade(ticker: "AAPL", account: nil, quantity: 10, date: date(0), action: .sell)

        for _ in 0..<100 {
            let grouped = JournalCSVImporter.groupedByMatchingTickers([buy, sell])
            #expect(grouped.first?.currentShareCount == 0)
        }
    }

    @Test func duplicateNormalizedHeadersDoNotCrashOrOverrideUsableData() throws {
        let url = try temporaryCSV(
            """
            Date,Ticker,ticker,Action,Quantity,Price
            2026-01-01,AAPL,,Buy,1,100
            """
        )
        defer { try? FileManager.default.removeItem(at: url) }

        let trades = try JournalCSVImporter().importTrades(from: url)

        #expect(trades.count == 1)
        #expect(trades.first?.ticker == "AAPL")
    }

    private func importedTrade(
        ticker: String,
        account: String?,
        quantity: Decimal,
        date: Date,
        action: TradeTransactionAction = .buy
    ) -> Trade {
        let trade = Trade(
            openedAt: date,
            ticker: ticker,
            account: account,
            shareCount: quantity,
            entryPrice: 100
        )
        trade.transactions = [
            TradeTransaction(date: date, action: action, quantity: quantity, price: 100)
        ]
        return trade
    }

    private func temporaryCSV(_ contents: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString)
            .appendingPathExtension("csv")
        try contents.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private func date(_ seconds: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(seconds))
    }
}
