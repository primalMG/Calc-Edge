import Foundation

enum OnboardingEditTarget: Identifiable {
    case account(id: UUID, draft: OnboardingAccountDraft)
    case rule(id: UUID, draft: OnboardingRuleDraft)
    case playbook(id: UUID, draft: OnboardingSetupDraft)

    var id: String {
        switch self {
        case .account(let id, _):
            "account-\(id.uuidString)"
        case .rule(let id, _):
            "rule-\(id.uuidString)"
        case .playbook(let id, _):
            "playbook-\(id.uuidString)"
        }
    }

    var title: String {
        switch self {
        case .account:
            "Edit Account"
        case .rule:
            "Edit Rule"
        case .playbook:
            "Edit Setup"
        }
    }
}

enum OnboardingEditResult {
    case account(id: UUID, draft: OnboardingAccountDraft)
    case rule(id: UUID, draft: OnboardingRuleDraft)
    case playbook(id: UUID, draft: OnboardingSetupDraft)
}
