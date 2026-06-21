import Foundation

struct OnboardingSession {
    var currentStep = OnboardingStep.welcome
    var selectedGoal = OnboardingGoal.journal
    var includeAccountSetup = true
    var includeFrameworkSetup = true
    var accountDraft = OnboardingAccountDraft()
    var ruleDraft = OnboardingRuleDraft()
    var setupDraft = OnboardingSetupDraft()
    var accountResult = OnboardingSetupResult.notSelected
    var ruleResult = OnboardingSetupResult.notSelected
    var playbookResult = OnboardingSetupResult.notSelected
    var pendingDiscardStep: OnboardingStep?

    var flow: OnboardingFlow {
        OnboardingFlow(
            includeAccount: includeAccountSetup,
            includeFramework: includeFrameworkSetup
        )
    }

    var navigationTitle: String {
        switch currentStep {
        case .welcome:
            "Welcome"
        case .account:
            "Account Setup"
        case .rulebook:
            "Rulebook Setup"
        case .playbook:
            "Playbook Setup"
        case .allSet:
            "All Set"
        }
    }

    mutating func start() {
        accountResult = includeAccountSetup ? .skipped : .notSelected
        ruleResult = includeFrameworkSetup ? .skipped : .notSelected
        playbookResult = includeFrameworkSetup ? .skipped : .notSelected
        currentStep = flow.next(after: .welcome) ?? .allSet
    }

    func progress(for step: OnboardingStep) -> OnboardingStepProgress {
        let setupSteps = flow.setupSteps
        let current = setupSteps.firstIndex(of: step).map { $0 + 1 } ?? 1
        return OnboardingStepProgress(current: current, total: max(setupSteps.count, 1))
    }

    mutating func requestSkip() {
        guard currentDraftIsDirty else {
            markCurrentStepSkipped()
            advance()
            return
        }

        pendingDiscardStep = currentStep
    }

    mutating func discardAndAdvance() {
        guard pendingDiscardStep == currentStep else {
            pendingDiscardStep = nil
            return
        }

        resetCurrentDraft()
        pendingDiscardStep = nil
        markCurrentStepSkipped()
        advance()
    }

    mutating func markCreated(_ step: OnboardingStep, name: String) {
        switch step {
        case .account:
            accountResult = .created(name: name)
        case .rulebook:
            ruleResult = .created(name: name)
        case .playbook:
            playbookResult = .created(name: name)
        case .welcome, .allSet:
            return
        }

        advance()
    }

    private var currentDraftIsDirty: Bool {
        switch currentStep {
        case .account:
            accountDraft.isDirty
        case .rulebook:
            ruleDraft.isDirty
        case .playbook:
            setupDraft.isDirty
        case .welcome, .allSet:
            false
        }
    }

    private mutating func resetCurrentDraft() {
        switch currentStep {
        case .account:
            accountDraft = OnboardingAccountDraft()
        case .rulebook:
            ruleDraft = OnboardingRuleDraft()
        case .playbook:
            setupDraft = OnboardingSetupDraft()
        case .welcome, .allSet:
            break
        }
    }

    private mutating func markCurrentStepSkipped() {
        switch currentStep {
        case .account:
            accountResult = .skipped
        case .rulebook:
            ruleResult = .skipped
        case .playbook:
            playbookResult = .skipped
        case .welcome, .allSet:
            break
        }
    }

    private mutating func advance() {
        currentStep = flow.next(after: currentStep) ?? .allSet
    }
}
