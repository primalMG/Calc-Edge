import Foundation

enum InstrumentType: String, Codable, CaseIterable {
    case stock
    case etf
    case option
    case future
    case forex
    case crypto
    case cfd
    case other
}
