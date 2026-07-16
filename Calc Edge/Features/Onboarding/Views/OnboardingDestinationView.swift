import SwiftUI

struct OnboardingDestinationView: View {
    @Binding var selectedGoal: OnboardingGoal

    let onComplete: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Where Do You Want to Start?", systemImage: "arrow.forward.circle")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Choose where Calc Edge opens. You can switch sections at any time.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                OnboardingDestinationPicker(selectedGoal: $selectedGoal)

                Button(action: onComplete) {
                    Label("Open \(selectedGoal.startDestination.title)", systemImage: "arrow.forward.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
                .accessibilityIdentifier("onboarding.finish")
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .accessibilityIdentifier("onboarding.step.destination")
    }
}
