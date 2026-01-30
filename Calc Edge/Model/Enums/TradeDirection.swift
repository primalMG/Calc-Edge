import Foundation

enum TradeDirection: String, Codable, CaseIterable {
    case long, short
}

enum OptionType: String, Codable, CaseIterable {
    case call, put
}
