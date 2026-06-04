import Foundation

enum ValueDisplayFormatter {
    static func decimal(_ value: Decimal, fractionDigits: Int? = nil) -> String {
        if let fractionDigits {
            return formattedDecimal(value, fractionDigits: fractionDigits)
        }

        return NSDecimalNumber(decimal: value).stringValue
    }

    static func decimal(_ value: Decimal?, placeholder: String = "Waiting for inputs", fractionDigits: Int? = nil) -> String {
        guard let value else { return placeholder }
        return decimal(value, fractionDigits: fractionDigits)
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

    private static func formattedDecimal(_ value: Decimal, fractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits

        return formatter.string(from: NSDecimalNumber(decimal: value)) ?? NSDecimalNumber(decimal: value).stringValue
    }
}
