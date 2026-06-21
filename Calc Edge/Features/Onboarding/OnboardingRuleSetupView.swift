import SwiftUI

struct OnboardingRuleSetupView: View {
    @Binding var draft: OnboardingRuleDraft

    let progress: OnboardingStepProgress
    let onSave: () -> Void
    let onSkip: () -> Void

    var body: some View {
        OnboardingSetupStepView(
            progress: progress,
            title: "Create Your First Rule",
            subtitle: "Define one decision rule you want to check consistently before or after a trade.",
            systemImage: "checklist.checked",
            onSave: onSave,
            onSkip: onSkip
        ) {
            OnboardingRuleForm(draft: $draft)
        }
        .accessibilityIdentifier("onboarding.step.rulebook")
    }
}
