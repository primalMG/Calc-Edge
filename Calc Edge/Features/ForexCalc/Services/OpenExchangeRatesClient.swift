//
//  OpenExchangeRatesClient.swift
//  Calc Edge
//
//  Created by Codex on 15/04/2026.
//

import Foundation

struct OpenExchangeRatesLatestResponse: Decodable {
    let disclaimer: String?
    let license: String?
    let timestamp: TimeInterval
    let base: String
    let rates: [String: Decimal]
}

struct OpenExchangeRatesSnapshot {
    let pairRate: Decimal
    let quoteToAccountRate: Decimal
}

enum OpenExchangeRatesError: LocalizedError {
    case invalidPair(String)
    case invalidCurrencyCode(String)
    case invalidURL
    case invalidResponse
    case requestFailed(statusCode: Int, message: String?)
    case missingRate(symbol: String)
    case invalidRate(symbol: String)

    var errorDescription: String? {
        switch self {
        case let .invalidPair(pair):
            return "Invalid forex pair '\(pair)'. Use format like EURUSD."
        case let .invalidCurrencyCode(code):
            return "Invalid currency code '\(code)'."
        case .invalidURL:
            return "Could not build Open Exchange Rates request URL."
        case .invalidResponse:
            return "Received an invalid response from Open Exchange Rates."
        case let .requestFailed(statusCode, message):
            if let message, !message.isEmpty {
                return "Open Exchange Rates request failed (\(statusCode)): \(message)"
            }
            return "Open Exchange Rates request failed (\(statusCode))."
        case let .missingRate(symbol):
            return "Missing rate for currency '\(symbol)'."
        case let .invalidRate(symbol):
            return "Invalid zero rate for currency '\(symbol)'."
        }
    }
}

struct OpenExchangeRatesClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared, decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.decoder = decoder
    }

    func latestRates(appID: String, symbols: [String] = []) async throws -> OpenExchangeRatesLatestResponse {
        let cleanedAppID = appID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedAppID.isEmpty else {
            throw OpenExchangeRatesError.requestFailed(statusCode: 401, message: "Missing app_id.")
        }

        var components = URLComponents(string: "https://openexchangerates.org/api/latest.json")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "app_id", value: cleanedAppID)
        ]

        let cleanedSymbols = normalizeSymbols(symbols)
        if !cleanedSymbols.isEmpty {
            queryItems.append(URLQueryItem(name: "symbols", value: cleanedSymbols.joined(separator: ",")))
        }
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw OpenExchangeRatesError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.allHTTPHeaderFields = ["accept": "application/json"]

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenExchangeRatesError.invalidResponse
        }

        guard (200 ... 299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8)
            throw OpenExchangeRatesError.requestFailed(statusCode: httpResponse.statusCode, message: message)
        }

        return try decoder.decode(OpenExchangeRatesLatestResponse.self, from: data)
    }

    func latestRatesSnapshot(for pair: String, accountCurrency: String, appID: String) async throws -> OpenExchangeRatesSnapshot {
        let normalizedPair = normalizePair(pair)
        guard normalizedPair.count == 6 else {
            throw OpenExchangeRatesError.invalidPair(pair)
        }

        let baseCurrency = String(normalizedPair.prefix(3))
        let quoteCurrency = String(normalizedPair.suffix(3))
        let normalizedAccountCurrency = normalizeCurrency(accountCurrency)
        guard normalizedAccountCurrency.count == 3 else {
            throw OpenExchangeRatesError.invalidCurrencyCode(accountCurrency)
        }

        let response = try await latestRates(
            appID: appID,
            symbols: [baseCurrency, quoteCurrency, normalizedAccountCurrency]
        )

        guard let basePerUSD = response.rates[baseCurrency] else {
            throw OpenExchangeRatesError.missingRate(symbol: baseCurrency)
        }
        guard let quotePerUSD = response.rates[quoteCurrency] else {
            throw OpenExchangeRatesError.missingRate(symbol: quoteCurrency)
        }
        guard basePerUSD != 0 else {
            throw OpenExchangeRatesError.invalidRate(symbol: baseCurrency)
        }
        guard quotePerUSD != 0 else {
            throw OpenExchangeRatesError.invalidRate(symbol: quoteCurrency)
        }

        let pairRate = quotePerUSD / basePerUSD

        if quoteCurrency == normalizedAccountCurrency {
            return OpenExchangeRatesSnapshot(pairRate: pairRate, quoteToAccountRate: Decimal(1))
        }

        guard let accountPerUSD = response.rates[normalizedAccountCurrency] else {
            throw OpenExchangeRatesError.missingRate(symbol: normalizedAccountCurrency)
        }
        guard accountPerUSD != 0 else {
            throw OpenExchangeRatesError.invalidRate(symbol: normalizedAccountCurrency)
        }

        // API values are "currency per USD", so quote->account = accountPerUSD / quotePerUSD.
        let quoteToAccountRate = accountPerUSD / quotePerUSD
        return OpenExchangeRatesSnapshot(pairRate: pairRate, quoteToAccountRate: quoteToAccountRate)
    }

    private func normalizePair(_ pair: String) -> String {
        pair
            .uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "/", with: "")
    }

    private func normalizeCurrency(_ code: String) -> String {
        code
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
    }

    private func normalizeSymbols(_ symbols: [String]) -> [String] {
        let cleaned = symbols
            .map(normalizeCurrency)
            .filter { $0.count == 3 }

        return Array(Set(cleaned)).sorted()
    }
}
