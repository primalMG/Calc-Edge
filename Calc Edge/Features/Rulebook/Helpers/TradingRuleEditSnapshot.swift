import Foundation

struct TradingRuleEditSnapshot: Equatable {
    let title: String
    let category: String
    let ruleDescription: String?
    let checklistPrompt: String?
    let isActive: Bool

    init(rule: TradingRule) {
        title = rule.title
        category = rule.category
        ruleDescription = rule.ruleDescription
        checklistPrompt = rule.checklistPrompt
        isActive = rule.isActive
    }
}
