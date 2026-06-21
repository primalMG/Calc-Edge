import SwiftUI

struct OnboardingStepProgress {
    let current: Int
    let total: Int
}

struct OnboardingSetupStepView<Content: View>: View {
    let progress: OnboardingStepProgress
    let title: String
    let subtitle: String
    let systemImage: String
    let onSave: () -> Void
    let onSkip: () -> Void
    @ViewBuilder let content: Content

    init(
        progress: OnboardingStepProgress,
        title: String,
        subtitle: String,
        systemImage: String,
        onSave: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.progress = progress
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
        self.onSave = onSave
        self.onSkip = onSkip
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                OnboardingProgressHeader(progress: progress)
                OnboardingStepHeader(
                    title: title,
                    subtitle: subtitle,
                    systemImage: systemImage
                )
                content
                OnboardingStepActions(onSave: onSave, onSkip: onSkip)
            }
            .frame(maxWidth: 720, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}

struct OnboardingFormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        FormSectionContainer(title, style: .standard) {
            content
        }
    }
}

private struct OnboardingProgressHeader: View {
    let progress: OnboardingStepProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step \(progress.current) of \(progress.total)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ProgressView(value: Double(progress.current), total: Double(progress.total))
                .accessibilityLabel("Onboarding progress")
                .accessibilityValue("Step \(progress.current) of \(progress.total)")
        }
    }
}

private struct OnboardingStepHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: systemImage)
                .font(.title2)
                .fontWeight(.semibold)

            Text(subtitle)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct OnboardingStepActions: View {
    let onSave: () -> Void
    let onSkip: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button("Skip", action: onSkip)
                .buttonStyle(.bordered)
                .accessibilityIdentifier("onboarding.skip")

            Button(action: onSave) {
                Label("Save & Continue", systemImage: "arrow.forward")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("onboarding.save")
        }
    }
}
