import SwiftUI

struct OnboardingWelcomeView: View {
    @Binding var includeAccountSetup: Bool
    @Binding var includeFrameworkSetup: Bool

    let onContinue: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                OnboardingWelcomeHeader()
                OnboardingOptionsSection(
                    includeAccountSetup: $includeAccountSetup,
                    includeFrameworkSetup: $includeFrameworkSetup
                )
                OnboardingWelcomeActions(
                    summary: firstSessionSummary,
                    onContinue: onContinue,
                    onNotNow: onNotNow
                )
            }
            .frame(maxWidth: 920, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .accessibilityIdentifier("onboarding.step.welcome")
    }

    private var firstSessionSummary: String {
        switch (includeAccountSetup, includeFrameworkSetup) {
        case (true, true):
            return "We'll guide you through your first account, rule, and playbook setup before you choose where to start."
        case (true, false):
            return "We'll guide you through your first account before you choose where to start."
        case (false, true):
            return "We'll guide you through your first rule and playbook setup before you choose where to start."
        case (false, false):
            return "Continue without initial setup. You can add accounts, rules, and trading setups later."
        }
    }
}

private struct OnboardingWelcomeHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Calc Edge", systemImage: "chart.line.uptrend.xyaxis")
                .font(.title)
                .fontWeight(.semibold)

            Text("Set up a trading journal around risk, process, and review.")
                .font(.title2)
                .fontWeight(.semibold)
                .fixedSize(horizontal: false, vertical: true)

            Text("Choose how much context to add now. You can adjust accounts, rules, setups, and imports later from the app.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct OnboardingOptionsSection: View {
    @Binding var includeAccountSetup: Bool
    @Binding var includeFrameworkSetup: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            OnboardingSectionHeader(
                title: "Suggested Setup",
                subtitle: "Keep these on if you want the journal and insights to have useful context from day one."
            )

            VStack(spacing: 0) {
                OnboardingToggleRow(
                    title: "Create an account profile",
                    detail: "Track account size, broker, and default currency.",
                    systemImage: "person.crop.circle",
                    identifier: "onboarding.includeAccount",
                    isOn: $includeAccountSetup
                )

                Divider()

                OnboardingToggleRow(
                    title: "Define rules and setups",
                    detail: "Capture entry rules, exits, and A+ setup criteria before reviewing trades.",
                    systemImage: "checklist.checked",
                    identifier: "onboarding.includeFramework",
                    isOn: $includeFrameworkSetup
                )
            }
            .background(.background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.quaternary, lineWidth: 1)
            }
        }
    }
}

private struct OnboardingWelcomeActions: View {
    let summary: String
    let onContinue: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            OnboardingSectionHeader(title: "First Session", subtitle: summary)

            Button(action: onContinue) {
                Label("Continue Setup", systemImage: "arrow.forward.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityIdentifier("onboarding.continue")

            Button("Not now", action: onNotNow)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
    }
}

private struct OnboardingSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}


private struct OnboardingToggleRow: View {
    let title: String
    let detail: String
    let systemImage: String
    let identifier: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .frame(width: 28)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)

                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .toggleStyle(.switch)
        .accessibilityIdentifier(identifier)
        .padding(14)
    }
}
