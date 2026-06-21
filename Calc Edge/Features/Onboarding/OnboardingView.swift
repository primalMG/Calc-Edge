import SwiftUI

struct OnboardingView: View {
    let completeOnboarding: (RootTab) -> Void

    @State private var selectedGoal = OnboardingGoal.journal
    @State private var includeAccountSetup = true
    @State private var includeFrameworkSetup = true

    init(onComplete: @escaping (RootTab) -> Void) {
        self.completeOnboarding = onComplete
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    goalSection
                    setupSection
                    nextStepSection
                }
                .frame(maxWidth: 920, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .navigationTitle("Welcome")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        completeOnboarding(.journal)
                    }
                        .accessibilityLabel("Skip onboarding")
                }
            }
        }
    }

    private var header: some View {
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

    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            OnboardingSectionHeader(
                title: "Start With",
                subtitle: "This keeps the first session focused."
            )

            LazyVGrid(columns: gridColumns, alignment: .leading, spacing: 12) {
                ForEach(OnboardingGoal.allCases) { goal in
                    OnboardingGoalButton(
                        goal: goal,
                        isSelected: goal == selectedGoal
                    ) {
                        selectedGoal = goal
                    }
                }
            }
        }
    }

    private var setupSection: some View {
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

    private var nextStepSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            OnboardingSectionHeader(
                title: "First Session",
                subtitle: firstSessionSummary
            )

            Button(action: finishWithSelectedGoal) {
                Label("Start Using Calc Edge", systemImage: "arrow.forward.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button("Not now") {
                completeOnboarding(.journal)
            }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
        }
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

    private func finishWithSelectedGoal() {
        completeOnboarding(selectedGoal.rootTab)
    }

    private var gridColumns: [GridItem] {
        [
            GridItem(.adaptive(minimum: 240), spacing: 12, alignment: .top)
        ]
    }
}

private enum OnboardingGoal: String, CaseIterable, Identifiable {
    case journal
    case risk
    case forex
    case review

    var id: String { rawValue }

    var title: String {
        switch self {
        case .journal:
            "Journal Trades"
        case .risk:
            "Calculate Risk"
        case .forex:
            "Track Forex"
        case .review:
            "Review Performance"
        }
    }

    var detail: String {
        switch self {
        case .journal:
            "Log entries, exits, process notes, and attachments."
        case .risk:
            "Size stock positions from account risk and trade levels."
        case .forex:
            "Save currency calculations and reference exchange rates."
        case .review:
            "Build habits around calendar reviews and journal insights."
        }
    }

    var systemImage: String {
        switch self {
        case .journal:
            "book"
        case .risk:
            "chart.line.uptrend.xyaxis"
        case .forex:
            "dollarsign.circle"
        case .review:
            "calendar"
        }
    }

    var nextStep: String {
        switch self {
        case .journal:
            "create or import a journal entry"
        case .risk:
            "open the stock risk calculator"
        case .forex:
            "create a forex calculation"
        case .review:
            "open the review calendar"
        }
    }

    var rootTab: RootTab {
        switch self {
        case .journal:
            .journal
        case .risk:
            #if os(macOS)
            .stockCalc
            #else
            .calculators
            #endif
        case .forex:
            #if os(macOS)
            .forexCalc
            #else
            .calculators
            #endif
        case .review:
            .reviewCalendar
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
            VStack(alignment: .leading, spacing: 10) {
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

#Preview {
    OnboardingView { _ in }
}
