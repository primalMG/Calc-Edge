import SwiftData

@MainActor
struct OnboardingSetupSaver {
    func saveAccount(
        _ sourceDraft: OnboardingAccountDraft,
        in modelContext: ModelContext
    ) throws -> OnboardingAccountDraft {
        let (draft, account) = try sourceDraft.makeModel()
        modelContext.insert(account)

        do {
            try modelContext.save()
            return draft
        } catch {
            modelContext.delete(account)
            throw error
        }
    }

    func saveRule(
        _ sourceDraft: OnboardingRuleDraft,
        in modelContext: ModelContext
    ) throws -> OnboardingRuleDraft {
        let (draft, rule) = try sourceDraft.makeModel()
        modelContext.insert(rule)

        do {
            try modelContext.save()
            return draft
        } catch {
            modelContext.delete(rule)
            throw error
        }
    }

    func saveSetup(
        _ sourceDraft: OnboardingSetupDraft,
        in modelContext: ModelContext
    ) throws -> OnboardingSetupDraft {
        let (draft, setup) = try sourceDraft.makeModel()
        modelContext.insert(setup)

        do {
            try modelContext.save()
            return draft
        } catch {
            modelContext.delete(setup)
            throw error
        }
    }
}
