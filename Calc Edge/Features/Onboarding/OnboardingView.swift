import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext

    let completeOnboarding: (AppStartDestination) -> Void
    private let setupSaver = OnboardingSetupSaver()

    @State private var session = OnboardingSession()
    @State private var editTarget: OnboardingEditTarget?
    @State private var errorMessage: String?
    @State private var validationError: OnboardingDraftError?
    @State private var isSkipSetupConfirmationPresented = false

    private var discardConfirmationBinding: Binding<Bool> {
        Binding(
            get: { session.pendingDiscardStep != nil },
            set: { isPresented in
                if !isPresented {
                    session.pendingDiscardStep = nil
                }
            }
        )
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    init(onComplete: @escaping (AppStartDestination) -> Void) {
        completeOnboarding = onComplete
    }

    var body: some View {
        NavigationStack {
            stepContent
                .navigationTitle(session.navigationTitle)
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .toolbar {
                    if session.currentStep == .destination {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(action: returnFromDestination) {
                                Label("Back", systemImage: "chevron.left")
                            }
                            .accessibilityLabel(destinationBackLabel)
                            .accessibilityIdentifier("onboarding.destination.back")
                        }
                    }
                }
        }
        .sheet(item: $editTarget) { target in
            OnboardingEditSheet(target: target, onSaved: applyEdit)
        }
        .confirmationDialog(
            "Discard this draft?",
            isPresented: discardConfirmationBinding,
            titleVisibility: .visible
        ) {
            Button("Discard & Continue", role: .destructive, action: discardAndAdvance)
            Button("Keep Editing", role: .cancel, action: keepEditing)
        } message: {
            Text("Your changes on this step have not been saved.")
        }
        .alert("Continue without setup?", isPresented: $isSkipSetupConfirmationPresented) {
            Button("Continue Without Setup", action: confirmSkippingSetup)
                .accessibilityIdentifier("onboarding.confirmWithoutSetup")
            Button("Keep Setting Up", role: .cancel) {}
                .accessibilityIdentifier("onboarding.keepSettingUp")
        } message: {
            Text("You can add accounts, rules, and trading setups later from the app.")
        }
        .alert("Couldn't Save", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel, action: dismissError)
        } message: {
            Text(errorMessage ?? "Review the form and try again.")
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch session.currentStep {
        case .welcome:
            OnboardingWelcomeView(
                includeAccountSetup: $session.includeAccountSetup,
                includeFrameworkSetup: $session.includeFrameworkSetup,
                onContinue: startSetup,
                onNotNow: requestSkippingSetup
            )
        case .account:
            OnboardingAccountSetupView(
                draft: $session.accountDraft,
                validationError: $validationError,
                progress: session.progress(for: .account),
                onSave: saveAccount,
                onSkip: requestSkip
            )
        case .rulebook:
            OnboardingRuleSetupView(
                draft: $session.ruleDraft,
                validationError: $validationError,
                progress: session.progress(for: .rulebook),
                onSave: saveRule,
                onSkip: requestSkip
            )
        case .playbook:
            OnboardingPlaybookSetupView(
                draft: $session.setupDraft,
                validationError: $validationError,
                progress: session.progress(for: .playbook),
                onSave: saveSetup,
                onSkip: requestSkip
            )
        case .review:
            OnboardingReviewView(
                accountResult: session.accountResult,
                ruleResult: session.ruleResult,
                playbookResult: session.playbookResult,
                onEditAccount: editAccount,
                onEditRule: editRule,
                onEditPlaybook: editPlaybook,
                onContinue: showDestination
            )
        case .destination:
            OnboardingDestinationView(
                selectedGoal: $session.selectedGoal,
                onComplete: finishWithSelectedGoal
            )
        }
    }

    private func startSetup() {
        guard session.hasSelectedSetup else {
            requestSkippingSetup()
            return
        }

        session.start()
    }

    private func requestSkip() {
        validationError = nil
        session.requestSkip()
    }

    private func discardAndAdvance() {
        validationError = nil
        session.discardAndAdvance()
    }

    private func keepEditing() {
        session.pendingDiscardStep = nil
    }

    private func requestSkippingSetup() {
        isSkipSetupConfirmationPresented = true
    }

    private func confirmSkippingSetup() {
        isSkipSetupConfirmationPresented = false
        session.skipSetup()
    }

    private func finishWithSelectedGoal() {
        completeOnboarding(session.selectedGoal.startDestination)
    }

    private func showDestination() {
        session.showDestination()
    }

    private func returnFromDestination() {
        session.returnFromDestination()
    }

    private var destinationBackLabel: String {
        switch session.destinationOrigin {
        case .welcome:
            "Back to Welcome"
        case .review:
            "Back to Review"
        }
    }

    private func saveAccount() {
        validationError = nil
        do {
            let savedItem = try setupSaver.saveAccount(session.accountDraft, in: modelContext)
            session.accountDraft = savedItem.draft
            session.markCreated(.account, id: savedItem.id, name: savedItem.draft.name)
        } catch {
            handleSaveError(error)
        }
    }

    private func saveRule() {
        validationError = nil
        do {
            let savedItem = try setupSaver.saveRule(session.ruleDraft, in: modelContext)
            session.ruleDraft = savedItem.draft
            session.markCreated(.rulebook, id: savedItem.id, name: savedItem.draft.title)
        } catch {
            handleSaveError(error)
        }
    }

    private func saveSetup() {
        validationError = nil
        do {
            let savedItem = try setupSaver.saveSetup(session.setupDraft, in: modelContext)
            session.setupDraft = savedItem.draft
            session.markCreated(.playbook, id: savedItem.id, name: savedItem.draft.name)
        } catch {
            handleSaveError(error)
        }
    }

    private func editAccount() {
        editTarget = session.editTarget(for: .account)
    }

    private func editRule() {
        editTarget = session.editTarget(for: .rulebook)
    }

    private func editPlaybook() {
        editTarget = session.editTarget(for: .playbook)
    }

    private func applyEdit(_ result: OnboardingEditResult) {
        session.apply(result)
    }

    private func show(_ error: Error) {
        errorMessage = error.localizedDescription
    }

    private func handleSaveError(_ error: Error) {
        if let draftError = error as? OnboardingDraftError {
            validationError = draftError
        } else {
            show(error)
        }
    }

    private func dismissError() {
        errorMessage = nil
    }
}

#Preview {
    OnboardingView { _ in }
}
