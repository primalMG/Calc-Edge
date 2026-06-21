import SwiftUI

struct OnboardingAccountForm: View {
    @Binding var draft: OnboardingAccountDraft

    var body: some View {
        Group {
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
    }
}

struct OnboardingRuleForm: View {
    @Binding var draft: OnboardingRuleDraft

    var body: some View {
        Group {
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
    }
}

struct OnboardingPlaybookForm: View {
    @Binding var draft: OnboardingSetupDraft

    var body: some View {
        Group {
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
    }
}
