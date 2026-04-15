//
//  AppSecrets.swift
//  Calc Edge
//
//  Created by Codex on 15/04/2026.
//

import Foundation

enum AppSecrets {
    static var openExchangeRatesAppID: String? {
        if let appID = readValue(for: "OPEN_EXCHANGE_RATES_APP_ID") {
            return appID
        }

        if let appID = readValue(for: "OPEN_EXCHANGE_RATES_API_KEY") {
            return appID
        }

        return nil
    }

    private static func readValue(for key: String) -> String? {
        guard let rawValue = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard !trimmed.contains("$(") else { return nil }
        guard trimmed != "YOUR_OPEN_EXCHANGE_RATES_APP_ID" else { return nil }
        guard trimmed != "API_KEY_HERE" else { return nil }
        return trimmed
    }
}
