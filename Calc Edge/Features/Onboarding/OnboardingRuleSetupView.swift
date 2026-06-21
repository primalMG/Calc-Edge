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
            OnboardingFormSection("Rule") {
                TextField("Rule Title", text: $draft.title)
                    .accessibilityIdentifier("onboarding.rule.title")
                TextField("Category", text: $draft.category)
                Toggle("Active", isOn: $draft.isActive)
            }

            OnboardingFormSection("Checklist") {
                TextField("Prompt shown during trade review", text: $draft.checklistPrompt, axis: .vertical)
                    .lineLimit(2...4)
            }

            OnboardingFormSection("Description") {
                TextField("Why this rule matters", text: $draft.description, axis: .vertical)
                    .lineLimit(3...8)
            }
        }
        .accessibilityIdentifier("onboarding.step.rulebook")
    }
}
