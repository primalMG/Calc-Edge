import Foundation

struct OnboardingAccountDraft: Equatable {
    var name = ""
    var broker = ""
    var balance = 0.0
    var currency = "USD"

    var isDirty: Bool { self != Self() }

    func normalized() throws -> Self {
        var draft = self
        draft.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.broker = broker.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.currency = currency.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        guard !draft.name.isEmpty else {
            throw OnboardingDraftError.accountNameRequired
        }

        guard draft.currency.utf8.count == 3,
              draft.currency.utf8.allSatisfy({ (65...90).contains(Int($0)) }) else {
            throw OnboardingDraftError.currencyRequired
        }

        guard draft.balance.isFinite, draft.balance >= 0 else {
            throw OnboardingDraftError.accountBalanceInvalid
        }

        return draft
    }

    func makeModel() throws -> (draft: Self, model: Account) {
        let draft = try normalized()
        let model = Account(
            accountName: draft.name,
            accountBroker: draft.broker,
            accountSize: draft.balance,
            currency: draft.currency
        )
        return (draft, model)
    }
}

struct OnboardingRuleDraft: Equatable {
    var title = ""
    var category = ""
    var checklistPrompt = ""
    var description = ""
    var isActive = true

    var isDirty: Bool { self != Self() }

    func normalized() throws -> Self {
        var draft = self
        draft.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.checklistPrompt = checklistPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.description = description.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !draft.title.isEmpty else {
            throw OnboardingDraftError.ruleTitleRequired
        }

        return draft
    }

    func makeModel() throws -> (draft: Self, model: TradingRule) {
        let draft = try normalized()
        let model = TradingRule(
            title: draft.title,
            category: draft.category,
            ruleDescription: draft.description.onboardingOptionalValue,
            checklistPrompt: draft.checklistPrompt.onboardingOptionalValue,
            isActive: draft.isActive
        )
        return (draft, model)
    }
}

struct OnboardingSetupDraft: Equatable {
    var name = ""
    var strategy = ""
    var timeframe = ""
    var catalyst = ""
    var criteria = ""
    var invalidation = ""
    var notes = ""
    var isActive = true

    var isDirty: Bool { self != Self() }

    func normalized() throws -> Self {
        var draft = self
        draft.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.strategy = strategy.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.timeframe = timeframe.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.catalyst = catalyst.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.criteria = criteria.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.invalidation = invalidation.trimmingCharacters(in: .whitespacesAndNewlines)
        draft.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !draft.name.isEmpty else {
            throw OnboardingDraftError.setupNameRequired
        }

        return draft
    }

    func makeModel() throws -> (draft: Self, model: TradingSetup) {
        let draft = try normalized()
        let model = TradingSetup(
            name: draft.name,
            strategyName: draft.strategy.onboardingOptionalValue,
            timeframe: draft.timeframe.onboardingOptionalValue,
            catalyst: draft.catalyst.onboardingOptionalValue,
            criteria: draft.criteria.onboardingOptionalValue,
            invalidation: draft.invalidation.onboardingOptionalValue,
            notes: draft.notes.onboardingOptionalValue,
            isActive: draft.isActive
        )
        return (draft, model)
    }
}

private extension String {
    var onboardingOptionalValue: String? {
        isEmpty ? nil : self
    }
}
