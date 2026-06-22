import SwiftUI

struct OnboardingDestinationPicker: View {
    @Binding var selectedGoal: OnboardingGoal

    var body: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 300), spacing: 12, alignment: .top)],
            alignment: .leading,
            spacing: 12
        ) {
            ForEach(OnboardingGoal.allCases) { goal in
                OnboardingDestinationButton(
                    goal: goal,
                    isSelected: goal == selectedGoal,
                    action: { selectedGoal = goal }
                )
            }
        }
    }
}

private struct OnboardingDestinationButton: View {
    let goal: OnboardingGoal
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        accessibleButton
            .accessibilityLabel(goal.title)
            .accessibilityValue(isSelected ? "Selected" : "Not selected")
            .accessibilityIdentifier("onboarding.destination.\(goal.rawValue)")
    }

    @ViewBuilder
    private var accessibleButton: some View {
        if isSelected {
            destinationButton
                .accessibilityAddTraits(.isSelected)
        } else {
            destinationButton
        }
    }

    private var destinationButton: some View {
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

                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 22)
                    .opacity(isSelected ? 1 : 0)
                    .accessibilityHidden(true)
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
    }
}
