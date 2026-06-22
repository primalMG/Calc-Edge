import SwiftUI

struct OnboardingRuleSetupView: View {
    @Binding var draft: OnboardingRuleDraft
    @Binding var validationError: OnboardingDraftError?

    let progress: OnboardingStepProgress
    let onSave: () -> Void
    let onSkip: () -> Void

    var body: some View {
        OnboardingSetupStepView(
            progress: progress,
            title: "Create Your First Rule",
            subtitle: "Define one decision rule you want to check consistently before or after a trade.",
            systemImage: "checklist.checked",
            stepIdentifier: "onboarding.step.rulebook",
            onSave: onSave,
            onSkip: onSkip
        ) {
            OnboardingRuleForm(
                draft: $draft,
                validationError: $validationError,
                onSubmit: onSave
            )
        }
    }
}
