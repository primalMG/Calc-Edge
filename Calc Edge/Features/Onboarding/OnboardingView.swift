import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext

    let completeOnboarding: (RootTab) -> Void
    private let setupSaver = OnboardingSetupSaver()

    @State private var session = OnboardingSession()
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
            let draft = try setupSaver.saveAccount(session.accountDraft, in: modelContext)
            session.accountDraft = draft
            session.markCreated(.account, name: draft.name)
        } catch {
            show(error)
        }
    }

    private func saveRule() {
        do {
            let draft = try setupSaver.saveRule(session.ruleDraft, in: modelContext)
            session.ruleDraft = draft
            session.markCreated(.rulebook, name: draft.title)
        } catch {
            show(error)
        }
    }

    private func saveSetup() {
        do {
            let draft = try setupSaver.saveSetup(session.setupDraft, in: modelContext)
            session.setupDraft = draft
            session.markCreated(.playbook, name: draft.name)
        } catch {
            show(error)
        }
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
