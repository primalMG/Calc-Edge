import SwiftUI

struct OnboardingPlaybookSetupView: View {
    @Binding var draft: OnboardingSetupDraft

    let progress: OnboardingStepProgress
    let onSave: () -> Void
    let onSkip: () -> Void

    var body: some View {
        OnboardingSetupStepView(
            progress: progress,
            title: "Create Your First Setup",
            subtitle: "Describe a repeatable trade setup and the conditions that make it valid.",
            systemImage: "rectangle.stack.badge.plus",
            onSave: onSave,
            onSkip: onSkip
        ) {
            OnboardingFormSection("Definition") {
                TextField("Setup Name", text: $draft.name)
                    .accessibilityIdentifier("onboarding.playbook.name")
                TextField("Strategy", text: $draft.strategy)
                TextField("Timeframe", text: $draft.timeframe)
                TextField("Catalyst", text: $draft.catalyst)
                Toggle("Active", isOn: $draft.isActive)
            }

            OnboardingFormSection("A+ Criteria") {
                TextField("What must be true before taking this setup?", text: $draft.criteria, axis: .vertical)
                    .lineLimit(3...8)
            }

            OnboardingFormSection("Invalidation") {
                TextField("What makes this setup invalid?", text: $draft.invalidation, axis: .vertical)
                    .lineLimit(2...6)
            }

            OnboardingFormSection("Notes") {
                TextField("Examples or reminders", text: $draft.notes, axis: .vertical)
                    .lineLimit(2...8)
            }
        }
        .accessibilityIdentifier("onboarding.step.playbook")
    }
}
