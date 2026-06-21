import SwiftData
import SwiftUI

struct OnboardingEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let target: OnboardingEditTarget
    let onSaved: (OnboardingEditResult) -> Void
    private let setupSaver = OnboardingSetupSaver()

    @State private var accountDraft: OnboardingAccountDraft
    @State private var ruleDraft: OnboardingRuleDraft
    @State private var setupDraft: OnboardingSetupDraft
    @State private var errorMessage: String?

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    errorMessage = nil
                }
            }
        )
    }

    init(
        target: OnboardingEditTarget,
        onSaved: @escaping (OnboardingEditResult) -> Void
    ) {
        self.target = target
        self.onSaved = onSaved

        switch target {
        case .account(_, let draft):
            _accountDraft = State(initialValue: draft)
            _ruleDraft = State(initialValue: OnboardingRuleDraft())
            _setupDraft = State(initialValue: OnboardingSetupDraft())
        case .rule(_, let draft):
            _accountDraft = State(initialValue: OnboardingAccountDraft())
            _ruleDraft = State(initialValue: draft)
            _setupDraft = State(initialValue: OnboardingSetupDraft())
        case .playbook(_, let draft):
            _accountDraft = State(initialValue: OnboardingAccountDraft())
            _ruleDraft = State(initialValue: OnboardingRuleDraft())
            _setupDraft = State(initialValue: draft)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    editorForm
                }
                .frame(maxWidth: 720, alignment: .leading)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .navigationTitle(target.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancel)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Changes", action: save)
                        .accessibilityIdentifier("onboarding.edit.save")
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 560, idealWidth: 680, minHeight: 440, idealHeight: 620)
        #endif
        .alert("Couldn't Save", isPresented: errorAlertBinding) {
            Button("OK", role: .cancel, action: dismissError)
        } message: {
            Text(errorMessage ?? "Review the form and try again.")
        }
    }

    @ViewBuilder
    private var editorForm: some View {
        switch target {
        case .account:
            OnboardingAccountForm(draft: $accountDraft)
        case .rule:
            OnboardingRuleForm(draft: $ruleDraft)
        case .playbook:
            OnboardingPlaybookForm(draft: $setupDraft)
        }
    }

    private func save() {
        do {
            let result: OnboardingEditResult

            switch target {
            case .account(let id, _):
                let draft = try setupSaver.updateAccount(id: id, with: accountDraft, in: modelContext)
                result = .account(id: id, draft: draft)
            case .rule(let id, _):
                let draft = try setupSaver.updateRule(id: id, with: ruleDraft, in: modelContext)
                result = .rule(id: id, draft: draft)
            case .playbook(let id, _):
                let draft = try setupSaver.updateSetup(id: id, with: setupDraft, in: modelContext)
                result = .playbook(id: id, draft: draft)
            }

            onSaved(result)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func cancel() {
        dismiss()
    }

    private func dismissError() {
        errorMessage = nil
    }
}
