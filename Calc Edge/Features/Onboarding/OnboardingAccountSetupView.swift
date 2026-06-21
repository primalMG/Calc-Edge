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
            OnboardingFormSection("Account") {
                TextField("Account Name", text: $draft.name)
                    .accessibilityIdentifier("onboarding.account.name")
                TextField("Broker", text: $draft.broker)
                TextField("Account Balance", value: $draft.balance, format: .number)
            }

            OnboardingFormSection("Currency") {
                TextField("Three-letter currency code", text: $draft.currency)
                    .textCase(.uppercase)
                    .accessibilityIdentifier("onboarding.account.currency")
            }
        }
        .accessibilityIdentifier("onboarding.step.account")
    }
}
