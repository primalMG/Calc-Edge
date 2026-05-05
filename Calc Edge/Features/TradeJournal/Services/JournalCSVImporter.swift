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

        let trade = Trade(
            openedAt: openedAt,
            ticker: ticker,
            market: row.value(for: Column.market),
            instrument: instrument,
            direction: direction,
            shareCount: quantity ?? 0,
            entryPrice: direction == .long ? price : nil,
            exitPrice: direction == .short ? price : nil,
            exchangeRate: exchangeRate,
            commissions: fee
        )

        trade.legs = [
            TradeLeg(
                symbol: ticker,
                legInstrument: instrument,
                quantity: quantity ?? 0,
                entryPrice: direction == .long ? price : nil,
                exitPrice: direction == .short ? price : nil
            )
        ]

        trade.transactions = [
            TradeTransaction(
                date: openedAt,
                action: TradeTransactionAction(csvAction: action, direction: direction),
                quantity: quantity ?? 0,
                price: price ?? 0,
                exchangeRate: exchangeRate,
                fees: fee
            )
        ]

        if let total, fee == nil {
            trade.plannedRiskAmount = total
        }

        return trade
    }
}

private extension TradeTransactionAction {
    init(csvAction: String?, direction: TradeDirection) {
        let normalized = csvAction?
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined() ?? ""

        switch normalized {
        case let value where value.contains("dividend"):
            self = .dividend
        case let value where value.contains("fee") || value.contains("charge") || value.contains("commission"):
            self = .fee
        case let value where value.contains("trim"):
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
    static let action = ["Action", "Side", "Type", "Transaction Type", "Trade Type"]
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
