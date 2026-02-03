import Foundation

enum ForexCalculatorType: String, Codable, CaseIterable {
    case pipValue
    case positionSize
    case margin
    case riskReward
    
    var displayName: String {
        switch self {
        case .pipValue:
            return "Pip Calc"
        case .positionSize:
            return "Position Size"
        case .margin:
            return "Margin"
        case .riskReward:
            return "Risk/Reward"
        }
    }
}
