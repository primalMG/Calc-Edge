import Foundation
import SwiftData

struct OnboardingSavedItem<Draft> {
    let id: UUID
    let draft: Draft
}

enum OnboardingSetupSaverError: LocalizedError {
    case itemNotFound(String)

    var errorDescription: String? {
        switch self {
        case .itemNotFound(let itemName):
            "The saved \(itemName) could not be found. Close onboarding and edit it from the app."
        }
    }
}

@MainActor
struct OnboardingSetupSaver {
    func saveAccount(
        _ sourceDraft: OnboardingAccountDraft,
        in modelContext: ModelContext
    ) throws -> OnboardingSavedItem<OnboardingAccountDraft> {
        let (draft, account) = try sourceDraft.makeModel()
        modelContext.insert(account)

        do {
            try modelContext.save()
            return OnboardingSavedItem(id: account.id, draft: draft)
        } catch {
            modelContext.delete(account)
            throw error
        }
    }

    func saveRule(
        _ sourceDraft: OnboardingRuleDraft,
        in modelContext: ModelContext
    ) throws -> OnboardingSavedItem<OnboardingRuleDraft> {
        let (draft, rule) = try sourceDraft.makeModel()
        modelContext.insert(rule)

        do {
            try modelContext.save()
            return OnboardingSavedItem(id: rule.ruleId, draft: draft)
        } catch {
            modelContext.delete(rule)
            throw error
        }
    }

    func saveSetup(
        _ sourceDraft: OnboardingSetupDraft,
        in modelContext: ModelContext
    ) throws -> OnboardingSavedItem<OnboardingSetupDraft> {
        let (draft, setup) = try sourceDraft.makeModel()
        modelContext.insert(setup)

        do {
            try modelContext.save()
            return OnboardingSavedItem(id: setup.setupId, draft: draft)
        } catch {
            modelContext.delete(setup)
            throw error
        }
    }

    func updateAccount(
        id: UUID,
        with sourceDraft: OnboardingAccountDraft,
        in modelContext: ModelContext
    ) throws -> OnboardingAccountDraft {
        let draft = try sourceDraft.normalized()
        let targetID = id
        let descriptor = FetchDescriptor<Account>(predicate: #Predicate { $0.id == targetID })

        guard let account = try modelContext.fetch(descriptor).first else {
            throw OnboardingSetupSaverError.itemNotFound("account")
        }

        let original = OnboardingAccountDraft(
            name: account.accountName,
            broker: account.accountBroker,
            balance: account.accountSize,
            currency: account.currency
        )

        apply(draft, to: account)

        do {
            try modelContext.save()
            return draft
        } catch {
            apply(original, to: account)
            throw error
        }
    }

    func updateRule(
        id: UUID,
        with sourceDraft: OnboardingRuleDraft,
        in modelContext: ModelContext
    ) throws -> OnboardingRuleDraft {
        let draft = try sourceDraft.normalized()
        let targetID = id
        let descriptor = FetchDescriptor<TradingRule>(predicate: #Predicate { $0.ruleId == targetID })

        guard let rule = try modelContext.fetch(descriptor).first else {
            throw OnboardingSetupSaverError.itemNotFound("rule")
        }

        let original = OnboardingRuleDraft(
            title: rule.title,
            category: rule.category,
            checklistPrompt: rule.checklistPrompt ?? "",
            description: rule.ruleDescription ?? "",
            isActive: rule.isActive
        )
        let originalUpdatedAt = rule.updatedAt

        apply(draft, to: rule)
        rule.updatedAt = .now

        do {
            try modelContext.save()
            return draft
        } catch {
            apply(original, to: rule)
            rule.updatedAt = originalUpdatedAt
            throw error
        }
    }

    func updateSetup(
        id: UUID,
        with sourceDraft: OnboardingSetupDraft,
        in modelContext: ModelContext
    ) throws -> OnboardingSetupDraft {
        let draft = try sourceDraft.normalized()
        let targetID = id
        let descriptor = FetchDescriptor<TradingSetup>(predicate: #Predicate { $0.setupId == targetID })

        guard let setup = try modelContext.fetch(descriptor).first else {
            throw OnboardingSetupSaverError.itemNotFound("setup")
        }

        let original = OnboardingSetupDraft(
            name: setup.name,
            strategy: setup.strategyName ?? "",
            timeframe: setup.timeframe ?? "",
            catalyst: setup.catalyst ?? "",
            criteria: setup.criteria ?? "",
            invalidation: setup.invalidation ?? "",
            notes: setup.notes ?? "",
            isActive: setup.isActive
        )
        let originalUpdatedAt = setup.updatedAt

        apply(draft, to: setup)
        setup.updatedAt = .now

        do {
            try modelContext.save()
            return draft
        } catch {
            apply(original, to: setup)
            setup.updatedAt = originalUpdatedAt
            throw error
        }
    }

    private func apply(_ draft: OnboardingAccountDraft, to account: Account) {
        account.accountName = draft.name
        account.accountBroker = draft.broker
        account.accountSize = draft.balance
        account.currency = draft.currency
    }

    private func apply(_ draft: OnboardingRuleDraft, to rule: TradingRule) {
        rule.title = draft.title
        rule.category = draft.category
        rule.checklistPrompt = optionalValue(draft.checklistPrompt)
        rule.ruleDescription = optionalValue(draft.description)
        rule.isActive = draft.isActive
    }

    private func apply(_ draft: OnboardingSetupDraft, to setup: TradingSetup) {
        setup.name = draft.name
        setup.strategyName = optionalValue(draft.strategy)
        setup.timeframe = optionalValue(draft.timeframe)
        setup.catalyst = optionalValue(draft.catalyst)
        setup.criteria = optionalValue(draft.criteria)
        setup.invalidation = optionalValue(draft.invalidation)
        setup.notes = optionalValue(draft.notes)
        setup.isActive = draft.isActive
    }

    private func optionalValue(_ value: String) -> String? {
        value.isEmpty ? nil : value
    }
}
