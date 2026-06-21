import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext

    let completeOnboarding: (RootTab) -> Void
    private let setupSaver = OnboardingSetupSaver()

    @State private var session = OnboardingSession()
    @State private var editTarget: OnboardingEditTarget?
    @State private var errorMessage: String?

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

    init(onComplete: @escaping (RootTab) -> Void) {
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
                    if session.currentStep == .welcome {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Skip", action: skipOnboarding)
                                .accessibilityLabel("Skip onboarding")
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
                selectedGoal: $session.selectedGoal,
                includeAccountSetup: $session.includeAccountSetup,
                includeFrameworkSetup: $session.includeFrameworkSetup,
                onContinue: startSetup,
                onNotNow: skipOnboarding
            )
        case .account:
            OnboardingAccountSetupView(
                draft: $session.accountDraft,
                progress: session.progress(for: .account),
                onSave: saveAccount,
                onSkip: requestSkip
            )
        case .rulebook:
            OnboardingRuleSetupView(
                draft: $session.ruleDraft,
                progress: session.progress(for: .rulebook),
                onSave: saveRule,
                onSkip: requestSkip
            )
        case .playbook:
            OnboardingPlaybookSetupView(
                draft: $session.setupDraft,
                progress: session.progress(for: .playbook),
                onSave: saveSetup,
                onSkip: requestSkip
            )
        case .allSet:
            OnboardingAllSetView(
                accountResult: session.accountResult,
                ruleResult: session.ruleResult,
                playbookResult: session.playbookResult,
                destinationTitle: session.selectedGoal.rootTab.title,
                onEditAccount: editAccount,
                onEditRule: editRule,
                onEditPlaybook: editPlaybook,
                onComplete: finishWithSelectedGoal
            )
        }
    }

    private func startSetup() {
        session.start()
    }

    private func requestSkip() {
        session.requestSkip()
    }

    private func discardAndAdvance() {
        session.discardAndAdvance()
    }

    private func keepEditing() {
        session.pendingDiscardStep = nil
    }

    private func skipOnboarding() {
        completeOnboarding(.journal)
    }

    private func finishWithSelectedGoal() {
        completeOnboarding(session.selectedGoal.rootTab)
    }

    private func saveAccount() {
        do {
            let savedItem = try setupSaver.saveAccount(session.accountDraft, in: modelContext)
            session.accountDraft = savedItem.draft
            session.markCreated(.account, id: savedItem.id, name: savedItem.draft.name)
        } catch {
            show(error)
        }
    }

    private func saveRule() {
        do {
            let savedItem = try setupSaver.saveRule(session.ruleDraft, in: modelContext)
            session.ruleDraft = savedItem.draft
            session.markCreated(.rulebook, id: savedItem.id, name: savedItem.draft.title)
        } catch {
            show(error)
        }
    }

    private func saveSetup() {
        do {
            let savedItem = try setupSaver.saveSetup(session.setupDraft, in: modelContext)
            session.setupDraft = savedItem.draft
            session.markCreated(.playbook, id: savedItem.id, name: savedItem.draft.name)
        } catch {
            show(error)
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

    private func dismissError() {
        errorMessage = nil
    }
}

#Preview {
    OnboardingView { _ in }
}
