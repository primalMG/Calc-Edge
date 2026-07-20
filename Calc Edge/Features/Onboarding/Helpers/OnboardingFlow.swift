import Foundation

enum OnboardingStep: String, Equatable {
    case welcome
    case account
    case rulebook
    case playbook
    case review
    case destination
}

enum OnboardingDestinationOrigin: Equatable {
    case welcome
    case review

    var step: OnboardingStep {
        switch self {
        case .welcome:
            .welcome
        case .review:
            .review
        }
    }
}

struct OnboardingFlow: Equatable {
    let includeAccount: Bool
    let includeFramework: Bool

    var steps: [OnboardingStep] {
        var result: [OnboardingStep] = [.welcome]

        if includeAccount {
            result.append(.account)
        }

        if includeFramework {
            result.append(contentsOf: [.rulebook, .playbook])
        }

        result.append(contentsOf: [.review, .destination])
        return result
    }

    var setupSteps: [OnboardingStep] {
        steps.filter { $0 != .welcome && $0 != .review && $0 != .destination }
    }

    func next(after step: OnboardingStep) -> OnboardingStep? {
        guard let index = steps.firstIndex(of: step), steps.indices.contains(index + 1) else {
            return nil
        }
        return steps[index + 1]
    }
}

enum OnboardingSetupResult: Equatable {
    case notSelected
    case skipped
    case created(name: String)
}

enum OnboardingDraftError: LocalizedError, Equatable {
    case accountNameRequired
    case currencyRequired
    case accountBalanceInvalid
    case ruleTitleRequired
    case setupNameRequired

    var errorDescription: String? {
        switch self {
        case .accountNameRequired:
            "Enter an account name before continuing."
        case .currencyRequired:
            "Use a three-letter currency code, such as USD."
        case .accountBalanceInvalid:
            "Enter an account balance of zero or more."
        case .ruleTitleRequired:
            "Enter a rule title before continuing."
        case .setupNameRequired:
            "Enter a setup name before continuing."
        }
    }
}
