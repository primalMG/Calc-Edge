import Foundation

enum ExitReason: String, Codable, CaseIterable {
    case targetHit
    case stopHit
    case manual
    case timeStop
    case trailingStop
    case invalidated
    case partial
    case other
}
