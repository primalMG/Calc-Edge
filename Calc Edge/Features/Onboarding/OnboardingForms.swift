import SwiftUI

struct OnboardingAccountForm: View {
    private enum Field: Hashable {
        case name
        case broker
        case balance
        case currency
    }

    @Binding var draft: OnboardingAccountDraft
    @Binding var validationError: OnboardingDraftError?
    let onSubmit: () -> Void

    @FocusState private var focusedField: Field?

    var body: some View {
        Group {
            OnboardingFormSection("Account") {
                OnboardingLabeledField(
                    "Account Name",
                    isRequired: true,
                    error: validationMessage(for: .accountNameRequired)
                ) {
                    TextField("Main Account", text: $draft.name)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .broker }
                        .accessibilityIdentifier("onboarding.account.name")
                }

                OnboardingLabeledField("Broker") {
                    TextField("Broker", text: $draft.broker)
                        .focused($focusedField, equals: .broker)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .balance }
                }

                OnboardingLabeledField("Account Balance") {
                    TextField("0", value: $draft.balance, format: .number)
                        .focused($focusedField, equals: .balance)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .currency }
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
            }

            OnboardingFormSection("Currency") {
                OnboardingLabeledField(
                    "Currency Code",
                    isRequired: true,
                    error: validationMessage(for: .currencyRequired)
                ) {
                    TextField("USD", text: $draft.currency)
                        .textCase(.uppercase)
                        .focused($focusedField, equals: .currency)
                        .submitLabel(.done)
                        .onSubmit(onSubmit)
                        #if os(iOS)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        #endif
                        .accessibilityIdentifier("onboarding.account.currency")
                }
            }
        }
        .onChange(of: validationError) { _, newError in
            switch newError {
            case .accountNameRequired:
                focusedField = .name
            case .currencyRequired:
                focusedField = .currency
            default:
                break
            }
        }
        .onChange(of: draft.name) { _, _ in
            clearValidation(.accountNameRequired)
        }
        .onChange(of: draft.currency) { _, _ in
            clearValidation(.currencyRequired)
        }
        #if os(macOS)
        .autocorrectionDisabled()
        #endif
    }

    private func validationMessage(for error: OnboardingDraftError) -> String? {
        validationError == error ? error.errorDescription : nil
    }

    private func clearValidation(_ error: OnboardingDraftError) {
        if validationError == error {
            validationError = nil
        }
    }
}

struct OnboardingRuleForm: View {
    private enum Field: Hashable {
        case title
        case category
    }

    @Binding var draft: OnboardingRuleDraft
    @Binding var validationError: OnboardingDraftError?
    let onSubmit: () -> Void

    @FocusState private var focusedField: Field?

    var body: some View {
        Group {
            OnboardingFormSection("Rule") {
                OnboardingLabeledField(
                    "Rule Title",
                    isRequired: true,
                    error: validationMessage
                ) {
                    TextField("Define Risk Before Entry", text: $draft.title)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .category }
                        .accessibilityIdentifier("onboarding.rule.title")
                }

                OnboardingLabeledField("Category") {
                    TextField("Risk", text: $draft.category)
                        .focused($focusedField, equals: .category)
                        .submitLabel(.done)
                        .onSubmit(onSubmit)
                }

                Toggle("Active", isOn: $draft.isActive)
            }

            OnboardingFormSection("Checklist") {
                OnboardingLabeledField("Review Prompt") {
                    TextField("Prompt shown during trade review", text: $draft.checklistPrompt, axis: .vertical)
                        .lineLimit(2...4)
                }
            }

            OnboardingFormSection("Description") {
                OnboardingLabeledField("Why This Rule Matters") {
                    TextField("Describe the purpose of this rule", text: $draft.description, axis: .vertical)
                        .lineLimit(3...8)
                }
            }
        }
        .onChange(of: validationError) { _, newError in
            if newError == .ruleTitleRequired {
                focusedField = .title
            }
        }
        .onChange(of: draft.title) { _, _ in
            if validationError == .ruleTitleRequired {
                validationError = nil
            }
        }
        #if os(macOS)
        .autocorrectionDisabled()
        #endif
    }

    private var validationMessage: String? {
        validationError == .ruleTitleRequired ? validationError?.errorDescription : nil
    }
}

struct OnboardingPlaybookForm: View {
    private enum Field: Hashable {
        case name
        case strategy
        case timeframe
        case catalyst
    }

    @Binding var draft: OnboardingSetupDraft
    @Binding var validationError: OnboardingDraftError?
    let onSubmit: () -> Void

    @FocusState private var focusedField: Field?

    var body: some View {
        Group {
            OnboardingFormSection("Definition") {
                OnboardingLabeledField(
                    "Setup Name",
                    isRequired: true,
                    error: validationMessage
                ) {
                    TextField("Opening Range Breakout", text: $draft.name)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .strategy }
                        .accessibilityIdentifier("onboarding.playbook.name")
                }

                OnboardingLabeledField("Strategy") {
                    TextField("Breakout", text: $draft.strategy)
                        .focused($focusedField, equals: .strategy)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .timeframe }
                }

                OnboardingLabeledField("Timeframe") {
                    TextField("5m", text: $draft.timeframe)
                        .focused($focusedField, equals: .timeframe)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .catalyst }
                }

                OnboardingLabeledField("Catalyst") {
                    TextField("Earnings", text: $draft.catalyst)
                        .focused($focusedField, equals: .catalyst)
                        .submitLabel(.done)
                        .onSubmit(onSubmit)
                }

                Toggle("Active", isOn: $draft.isActive)
            }

            OnboardingFormSection("A+ Criteria") {
                OnboardingLabeledField("Entry Criteria") {
                    TextField("What must be true before taking this setup?", text: $draft.criteria, axis: .vertical)
                        .lineLimit(3...8)
                }
            }

            OnboardingFormSection("Invalidation") {
                OnboardingLabeledField("Invalidation") {
                    TextField("What makes this setup invalid?", text: $draft.invalidation, axis: .vertical)
                        .lineLimit(2...6)
                }
            }

            OnboardingFormSection("Notes") {
                OnboardingLabeledField("Notes") {
                    TextField("Examples or reminders", text: $draft.notes, axis: .vertical)
                        .lineLimit(2...8)
                }
            }
        }
        .onChange(of: validationError) { _, newError in
            if newError == .setupNameRequired {
                focusedField = .name
            }
        }
        .onChange(of: draft.name) { _, _ in
            if validationError == .setupNameRequired {
                validationError = nil
            }
        }
        #if os(macOS)
        .autocorrectionDisabled()
        #endif
    }

    private var validationMessage: String? {
        validationError == .setupNameRequired ? validationError?.errorDescription : nil
    }
}

private struct OnboardingLabeledField<Content: View>: View {
    let title: String
    let isRequired: Bool
    let error: String?
    @ViewBuilder let content: Content

    init(
        _ title: String,
        isRequired: Bool = false,
        error: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.isRequired = isRequired
        self.error = error
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                if isRequired {
                    Text("Required")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            content

            if let error {
                Label(error, systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
