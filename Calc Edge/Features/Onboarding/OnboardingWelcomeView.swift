import SwiftUI

struct OnboardingWelcomeView: View {
    @Binding var selectedGoal: OnboardingGoal
    @Binding var includeAccountSetup: Bool
    @Binding var includeFrameworkSetup: Bool

    let onContinue: () -> Void
    let onNotNow: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                OnboardingWelcomeHeader()
                OnboardingGoalSection(selectedGoal: $selectedGoal)
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
        var steps = [selectedGoal.nextStep]

        if includeAccountSetup {
            steps.append("add your first account")
        }

        if includeFrameworkSetup {
            steps.append("capture one rule or setup")
        }

        return "After this, start with \(steps.joined(separator: ", "))."
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

            Text("Choose the workflow you care about first. You can adjust accounts, rules, setups, and imports later from the app.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct OnboardingGoalSection: View {
    @Binding var selectedGoal: OnboardingGoal

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            OnboardingSectionHeader(
                title: "Start With",
                subtitle: "This keeps the first session focused."
            )

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 240), spacing: 12, alignment: .top)],
                alignment: .leading,
                spacing: 12
            ) {
                ForEach(OnboardingGoal.allCases) { goal in
                    OnboardingGoalButton(
                        goal: goal,
                        isSelected: goal == selectedGoal,
                        action: { selectedGoal = goal }
                    )
                }
            }
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
                    isOn: $includeAccountSetup
                )

                Divider()

                OnboardingToggleRow(
                    title: "Define rules and setups",
                    detail: "Capture entry rules, exits, and A+ setup criteria before reviewing trades.",
                    systemImage: "checklist.checked",
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

private struct OnboardingGoalButton: View {
    let goal: OnboardingGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: goal.systemImage)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : .primary)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.title)
                        .font(.headline)
                        .foregroundStyle(isSelected ? .white : .primary)

                    Text(goal.detail)
                        .font(.subheadline)
                        .foregroundStyle(isSelected ? .white.opacity(0.82) : .secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 116, alignment: .topLeading)
            .background(isSelected ? Color.accentColor : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.18), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(goal.title)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
}

private struct OnboardingToggleRow: View {
    let title: String
    let detail: String
    let systemImage: String
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
        .padding(14)
    }
}
