import Foundation

enum ValueDisplayFormatter {
    static func decimal(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }

    static func decimal(_ value: Decimal?, placeholder: String = "Waiting for inputs") -> String {
        guard let value else { return placeholder }
        return decimal(value)
    }

    static func wholeNumber(_ value: Int?, placeholder: String = "Waiting for inputs") -> String {
        guard let value else { return placeholder }
        return String(value)
    }

    static func double(_ value: Double) -> String {
        NSDecimalNumber(decimal: Decimal(value)).stringValue
    }

    static func double(_ value: Double?, placeholder: String = "Waiting for inputs") -> String {
        guard let value else { return placeholder }
        return double(value)
    }
}
