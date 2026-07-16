import SwiftUI

struct OnboardingPlaybookSetupView: View {
    @Binding var draft: OnboardingSetupDraft
    @Binding var validationError: OnboardingDraftError?

    let progress: OnboardingStepProgress
    let onSave: () -> Void
    let onSkip: () -> Void

    var body: some View {
        OnboardingSetupStepView(
            progress: progress,
            title: "Create Your First Setup",
            subtitle: "Describe a repeatable trade setup and the conditions that make it valid.",
            systemImage: "rectangle.stack.badge.plus",
            stepIdentifier: "onboarding.step.playbook",
            onSave: onSave,
            onSkip: onSkip
        ) {
            OnboardingPlaybookForm(
                draft: $draft,
                validationError: $validationError,
                onSubmit: onSave
            )
        }
    }
}
