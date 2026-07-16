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
    var accountID: UUID?
    var ruleID: UUID?
    var playbookID: UUID?
    var pendingDiscardStep: OnboardingStep?
    var destinationOrigin = OnboardingDestinationOrigin.review

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
        case .review:
            "Review Your Setup"
        case .destination:
            "Get Started"
        }
    }

    mutating func start() {
        initializeSetupResults()

        guard let firstSetupStep = flow.setupSteps.first else {
            destinationOrigin = .welcome
            currentStep = .destination
            return
        }

        currentStep = firstSetupStep
    }

    mutating func skipSetup() {
        initializeSetupResults()
        destinationOrigin = .welcome
        currentStep = .destination
    }

    mutating func showDestination() {
        guard currentStep == .review else { return }
        destinationOrigin = .review
        currentStep = .destination
    }

    mutating func returnFromDestination() {
        guard currentStep == .destination else { return }
        currentStep = destinationOrigin.step
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

    mutating func markCreated(_ step: OnboardingStep, id: UUID, name: String) {
        switch step {
        case .account:
            accountID = id
            accountResult = .created(name: name)
        case .rulebook:
            ruleID = id
            ruleResult = .created(name: name)
        case .playbook:
            playbookID = id
            playbookResult = .created(name: name)
        case .welcome, .review, .destination:
            return
        }

        advance()
    }

    func editTarget(for step: OnboardingStep) -> OnboardingEditTarget? {
        switch step {
        case .account:
            guard case .created = accountResult, let accountID else { return nil }
            return .account(id: accountID, draft: accountDraft)
        case .rulebook:
            guard case .created = ruleResult, let ruleID else { return nil }
            return .rule(id: ruleID, draft: ruleDraft)
        case .playbook:
            guard case .created = playbookResult, let playbookID else { return nil }
            return .playbook(id: playbookID, draft: setupDraft)
        case .welcome, .review, .destination:
            return nil
        }
    }

    mutating func apply(_ result: OnboardingEditResult) {
        switch result {
        case .account(let id, let draft):
            guard accountID == id else { return }
            accountDraft = draft
            accountResult = .created(name: draft.name)
        case .rule(let id, let draft):
            guard ruleID == id else { return }
            ruleDraft = draft
            ruleResult = .created(name: draft.title)
        case .playbook(let id, let draft):
            guard playbookID == id else { return }
            setupDraft = draft
            playbookResult = .created(name: draft.name)
        }
    }

    private var currentDraftIsDirty: Bool {
        switch currentStep {
        case .account:
            accountDraft.isDirty
        case .rulebook:
            ruleDraft.isDirty
        case .playbook:
            setupDraft.isDirty
        case .welcome, .review, .destination:
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
        case .welcome, .review, .destination:
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
        case .welcome, .review, .destination:
            break
        }
    }

    private mutating func advance() {
        currentStep = flow.next(after: currentStep) ?? .review
    }

    private mutating func initializeSetupResults() {
        accountResult = includeAccountSetup ? .skipped : .notSelected
        ruleResult = includeFrameworkSetup ? .skipped : .notSelected
        playbookResult = includeFrameworkSetup ? .skipped : .notSelected
    }
}
