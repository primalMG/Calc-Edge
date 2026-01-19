import Foundation

enum MarketRegime: String, Codable, CaseIterable {
    case trending
    case choppy
    case rangeBound
    case volatile
    case unknown
}
