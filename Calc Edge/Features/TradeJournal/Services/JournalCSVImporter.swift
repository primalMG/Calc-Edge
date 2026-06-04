import Foundation
import SwiftCSV

enum JournalCSVImportError: LocalizedError {
    case noRows
    case noImportableRows

    var errorDescription: String? {
        switch self {
        case .noRows:
            "The selected CSV did not contain any rows."
        case .noImportableRows:
            "No importable trades were found in the selected CSV."
        }
    }
}

struct JournalCSVImporter {
    enum Broker {
        case automatic
        case trading212
    }

    var broker: Broker = .automatic

    func importTrades(from url: URL) throws -> [Trade] {
        let csv = try CSV<Named>(url: url, loadColumns: false)

        guard !csv.rows.isEmpty else {
            throw JournalCSVImportError.noRows
        }

        let trades = csv.rows.compactMap { row in
            trade(from: CSVRow(row))
        }

        guard !trades.isEmpty else {
            throw JournalCSVImportError.noImportableRows
        }

        return trades
    }

    @MainActor
    static func groupedByMatchingTickers(_ trades: [Trade]) -> [Trade] {
        let grouped = Dictionary(grouping: trades, by: TradeImportGroupKey.init)

        return grouped.values
            .map { group in
                guard group.count > 1 else {
                    return group[0]
                }

                return groupedTrade(from: group)
            }
            .sorted { $0.openedAt < $1.openedAt }
    }

    private func trade(from row: CSVRow) -> Trade? {
        let action = row.value(for: Column.action)
        let ticker = row.value(for: Column.ticker)?.uppercased()

        guard let ticker, !ticker.isEmpty else {
            return nil
        }

        let openedAt = row.value(for: Column.openedAt).flatMap(DateParser.date(from:)) ?? .now
        let direction = TradeDirection(action: action)
        let instrument = row.value(for: Column.instrument)
            .flatMap(InstrumentType.init(csvValue:))
            ?? .stock
        let price = row.decimal(for: Column.entryPrice)
        let total = row.decimal(for: Column.total)
        let quantity = row.decimal(for: Column.quantity)
        let fee = row.decimal(for: Column.commissions)
        let exchangeRate = row.decimal(for: Column.exchangeRate)
        let transactionAction = TradeTransactionAction(csvAction: action, direction: direction)
        let dividendAmount = transactionAction == .dividend ? total ?? price : nil
        let importedQuantity = transactionAction == .dividend ? 0 : quantity ?? 0
        let importedEntryPrice = transactionAction == .dividend ? nil : direction == .long ? price : nil
        let importedExitPrice = transactionAction == .dividend ? nil : direction == .short ? price : nil

        let trade = Trade(
            openedAt: openedAt,
            ticker: ticker,
            market: row.value(for: Column.market),
            instrument: instrument,
            direction: direction,
            shareCount: importedQuantity,
            entryPrice: importedEntryPrice,
            exitPrice: importedExitPrice,
            exchangeRate: exchangeRate,
            commissions: fee
        )

        trade.legs = [
            TradeLeg(
                symbol: ticker,
                legInstrument: instrument,
                quantity: importedQuantity,
                entryPrice: importedEntryPrice,
                exitPrice: importedExitPrice
            )
        ]

        trade.transactions = [
            TradeTransaction(
                date: openedAt,
                action: transactionAction,
                quantity: importedQuantity,
                price: transactionAction == .dividend ? 0 : price ?? 0,
                amount: dividendAmount,
                exchangeRate: exchangeRate,
                fees: fee
            )
        ]

        if let total, fee == nil, transactionAction != .dividend {
            trade.plannedRiskAmount = total
        }

        return trade
    }

    private static func groupedTrade(from trades: [Trade]) -> Trade {
        let sortedTrades = trades.sorted { $0.openedAt < $1.openedAt }
        let firstTrade = sortedTrades[0]
        let transactions = sortedTrades
            .flatMap { $0.transactions ?? [] }
            .sorted { $0.date < $1.date }
            .map { transaction in
                TradeTransaction(
                    date: transaction.date,
                    action: transaction.action,
                    quantity: transaction.quantity,
                    price: transaction.price,
                    amount: transaction.amount,
                    exchangeRate: transaction.exchangeRate,
                    fees: transaction.fees,
                    note: transaction.note
                )
            }
        let summary = TradePositionSummary(transactions: transactions)
        let exchangeRates = Set(sortedTrades.compactMap { $0.exchangeRate })

        let trade = Trade(
            openedAt: sortedTrades.map(\.openedAt).min() ?? firstTrade.openedAt,
            ticker: firstTrade.ticker,
            market: firstTrade.market,
            accountId: firstTrade.accountId,
            account: firstTrade.account,
            instrument: firstTrade.instrument,
            direction: firstTrade.direction,
            shareCount: summary.currentShareCount,
            entryPrice: firstTrade.direction == .long ? summary.averagePrice : nil,
            exitPrice: firstTrade.direction == .short ? firstTrade.exitPrice : nil,
            exchangeRate: exchangeRates.count == 1 ? exchangeRates.first : nil,
            plannedRiskAmount: sum(sortedTrades.compactMap(\.plannedRiskAmount)),
            commissions: sum(sortedTrades.compactMap(\.commissions))
        )

        trade.legs = [
            TradeLeg(
                symbol: firstTrade.ticker,
                legInstrument: firstTrade.instrument,
                quantity: summary.currentShareCount,
                entryPrice: firstTrade.direction == .long ? summary.averagePrice : nil,
                exitPrice: firstTrade.direction == .short ? firstTrade.exitPrice : nil
            )
        ]
        trade.transactions = transactions

        return trade
    }

    private static func sum(_ values: [Decimal]) -> Decimal? {
        guard let first = values.first else {
            return nil
        }

        return values.dropFirst().reduce(first, +)
    }
}

private struct TradeImportGroupKey: Hashable {
    let ticker: String
    let instrument: InstrumentType
    let accountId: UUID?
    let account: String?
    let market: String?

    init(trade: Trade) {
        ticker = trade.ticker.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        instrument = trade.instrument
        accountId = trade.accountId
        account = trade.account?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        market = trade.market?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}


private extension TradeTransactionAction {
    init(csvAction: String?, direction: TradeDirection) {
        let normalized = csvAction?
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined() ?? ""

        switch normalized {
        case let value where value.contains("dividend") || value.contains("CDIV"):
            self = .dividend
        case let value where value.contains("fee") || value.contains("charge") || value.contains("commission"):
            self = .fee
        case let value where value.contains("trim") || value.contains("NRAT"):
            self = .trim
        case let value where value.contains("add"):
            self = .add
        case let value where value.contains("sell"):
            self = .sell
        case let value where value.contains("buy"):
            self = .buy
        default:
            self = direction == .long ? .buy : .sell
        }
    }
}

private struct CSVRow {
    let values: [String: String]

    init(_ values: [String: String]) {
        self.values = Dictionary(
            uniqueKeysWithValues: values.map { key, value in
                (Self.normalized(key), value.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        )
    }

    func value(for aliases: [String]) -> String? {
        for alias in aliases {
            guard let value = values[Self.normalized(alias)], !value.isEmpty else {
                continue
            }

            return value
        }

        return nil
    }

    func decimal(for aliases: [String]) -> Decimal? {
        guard let value = value(for: aliases) else {
            return nil
        }

        let stripped = value
            .replacingOccurrences(of: "£", with: "")
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: "€", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return Decimal(string: stripped, locale: Locale(identifier: "en_US_POSIX"))
    }

    private static func normalized(_ value: String) -> String {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
    }
}

private enum Column {
    static let action = ["Action", "Side", "Type", "Transaction Type", "Trade Type", "Trans Code"]
    static let ticker = ["Ticker", "Symbol", "Instrument", "Market"]
    static let market = ["Market", "Exchange", "Venue", "Currency (Price / share)"]
    static let instrument = ["Instrument Type", "Asset Type", "Type", "Product Type"]
    static let openedAt = ["Time", "Date", "Opened At", "Open Time", "Execution Time", "Trade Date", "Created At", "Settle Date"]
    static let quantity = ["No. of shares", "Quantity", "Qty", "Shares", "Units", "Size"]
    static let entryPrice = ["Price / share", "Price", "Entry Price", "Open Price", "Average Price"]
    static let exchangeRate = ["Exchange rate", "Exchange Rate", "FX Rate", "Currency Exchange Rate", "Conversion Rate"]
    static let total = ["Total", "Value", "Amount", "Gross Amount", "Net Amount"]
    static let commissions = ["Commissions", "Commission", "Fees", "Fee", "Currency conversion fee", "Charges"]
}

private enum DateParser {
    nonisolated static func date(from value: String) -> Date? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        if let epoch = TimeInterval(trimmed) {
            return Date(timeIntervalSince1970: epoch > 10_000_000_000 ? epoch / 1000 : epoch)
        }

        let internet = ISO8601DateFormatter()
        internet.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let internetNoFraction = ISO8601DateFormatter()
        internetNoFraction.formatOptions = [.withInternetDateTime]

        let fullDate = ISO8601DateFormatter()
        fullDate.formatOptions = [.withFullDate]

        for formatter in [internet, internetNoFraction, fullDate] {
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        for format in [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy-MM-dd",
            "yyyy/MM/dd HH:mm:ss",
            "yyyy/MM/dd HH:mm",
            "yyyy/MM/dd",
            "dd/MM/yyyy HH:mm:ss",
            "dd/MM/yyyy HH:mm",
            "dd/MM/yyyy",
            "MM/dd/yyyy HH:mm:ss",
            "MM/dd/yyyy HH:mm",
            "MM/dd/yyyy",
            "dd-MM-yyyy HH:mm:ss",
            "dd-MM-yyyy HH:mm",
            "dd-MM-yyyy",
            "MM-dd-yyyy HH:mm:ss",
            "MM-dd-yyyy HH:mm",
            "MM-dd-yyyy",
            "dd MMM yyyy HH:mm:ss",
            "dd MMM yyyy HH:mm",
            "dd MMM yyyy",
            "MMM d, yyyy h:mm:ss a",
            "MMM d, yyyy h:mm a",
            "MMM d, yyyy",
            "yyyyMMdd",
            "yyyyMMddHHmmss"
        ] {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = .current
            formatter.dateFormat = format

            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        let fallbackStyles: [(DateFormatter.Style, DateFormatter.Style)] = [
            (.short, .short),
            (.medium, .short),
            (.long, .short),
            (.short, .none),
            (.medium, .none),
            (.long, .none)
        ]

        for styles in fallbackStyles {
            let formatter = DateFormatter()
            formatter.locale = .current
            formatter.timeZone = .current
            formatter.dateStyle = styles.0
            formatter.timeStyle = styles.1

            if let date = formatter.date(from: trimmed) {
                return date
            }
        }

        return nil
    }
}

private extension TradeDirection {
    init(action: String?) {
        let normalized = action?
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined() ?? ""

        if normalized.contains("sell") || normalized.contains("short") {
            self = .short
        } else {
            self = .long
        }
    }
}

private extension InstrumentType {
    nonisolated init?(csvValue: String) {
        let normalized = csvValue
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()

        switch normalized {
        case "stock", "share", "shares", "equity", "equities":
            self = .stock
        case "etf", "fund":
            self = .etf
        case "option", "options":
            self = .option
        case "future", "futures":
            self = .future
        case "forex", "fx", "currency", "currencies":
            self = .forex
        case "crypto", "cryptocurrency":
            self = .crypto
        case "cfd", "contractfordifference":
            self = .cfd
        case "other":
            self = .other
        default:
            return nil
        }
    }
}
