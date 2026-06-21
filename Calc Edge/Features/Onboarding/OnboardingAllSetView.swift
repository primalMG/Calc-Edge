import SwiftUI

struct OnboardingAllSetView: View {
    let accountResult: OnboardingSetupResult
    let ruleResult: OnboardingSetupResult
    let playbookResult: OnboardingSetupResult
    let destinationTitle: String
    let onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                OnboardingCompletionHeader()
                OnboardingResultsSummary(
                    accountResult: accountResult,
                    ruleResult: ruleResult,
                    playbookResult: playbookResult
                )

                Button(action: onComplete) {
                    Label("Open \(destinationTitle)", systemImage: "arrow.forward.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("onboarding.finish")
            }
            .frame(maxWidth: 680, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .accessibilityIdentifier("onboarding.step.allSet")
    }
}

private struct OnboardingCompletionHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.green)

            Text("You're All Set")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("Your starting workspace is ready. You can add or edit these items at any time.")
                .foregroundStyle(.secondary)
        }
    }
}

private struct OnboardingResultsSummary: View {
    let accountResult: OnboardingSetupResult
    let ruleResult: OnboardingSetupResult
    let playbookResult: OnboardingSetupResult

    var body: some View {
        VStack(spacing: 0) {
            OnboardingResultRow(title: "Account", systemImage: "person.crop.circle", result: accountResult)
            Divider()
            OnboardingResultRow(title: "Rulebook", systemImage: "checklist.checked", result: ruleResult)
            Divider()
            OnboardingResultRow(title: "Playbook", systemImage: "rectangle.stack", result: playbookResult)
        }
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.quaternary, lineWidth: 1)
        }
    }
}

private struct OnboardingResultRow: View {
    let title: String
    let systemImage: String
    let result: OnboardingSetupResult

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .frame(width: 28)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)

                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: statusImage)
                .foregroundStyle(statusColor)
                .accessibilityHidden(true)
        }
        .padding(14)
        .accessibilityElement(children: .combine)
    }

    private var detail: String {
        switch result {
        case .notSelected:
            "Not selected"
        case .skipped:
            "Skipped"
        case .created(let name):
            "Created: \(name)"
        }
    }

    private var statusImage: String {
        switch result {
        case .created:
            "checkmark.circle.fill"
        case .skipped, .notSelected:
            "minus.circle"
        }
    }

    private var statusColor: Color {
        switch result {
        case .created:
            .green
        case .skipped, .notSelected:
            .secondary
        }
    }
}
