import Foundation
import SwiftUI

func optionalTextBinding(_ binding: Binding<String?>) -> Binding<String> {
    Binding(
        get: { binding.wrappedValue ?? "" },
        set: { newValue in
            binding.wrappedValue = newValue.isEmpty ? nil : newValue
        }
    )
}

func optionalDecimalBinding(_ binding: Binding<Decimal?>) -> Binding<String> {
    Binding(
        get: {
            guard let value = binding.wrappedValue else { return "" }
            return NSDecimalNumber(decimal: value).stringValue
        },
        set: { newValue in
            let cleaned = newValue.replacingOccurrences(of: ",", with: ".")
            if cleaned.isEmpty {
                binding.wrappedValue = nil
            } else if let decimal = Decimal(string: cleaned) {
                binding.wrappedValue = decimal
            }
        }
    )
}

func decimalBinding(_ binding: Binding<Decimal>) -> Binding<String> {
    Binding(
        get: {
            NSDecimalNumber(decimal: binding.wrappedValue).stringValue
        },
        set: { newValue in
            let cleaned = newValue.replacingOccurrences(of: ",", with: ".")
            if cleaned.isEmpty {
                binding.wrappedValue = 0
            } else if let decimal = Decimal(string: cleaned) {
                binding.wrappedValue = decimal
            }
        }
    )
}
