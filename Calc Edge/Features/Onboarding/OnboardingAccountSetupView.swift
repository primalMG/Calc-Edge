import SwiftUI

struct OnboardingAccountSetupView: View {
    @Binding var draft: OnboardingAccountDraft

    let progress: OnboardingStepProgress
    let onSave: () -> Void
    let onSkip: () -> Void

    var body: some View {
        OnboardingSetupStepView(
            progress: progress,
            title: "Create Your First Account",
            subtitle: "Add the account you will use most often. You can add more accounts later.",
            systemImage: "person.crop.circle",
            onSave: onSave,
            onSkip: onSkip
        ) {
            OnboardingAccountForm(draft: $draft)
        }
        .accessibilityIdentifier("onboarding.step.account")
    }
}
