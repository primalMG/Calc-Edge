import SwiftData
import Testing
@testable import Calc_Edge

struct OnboardingFlowTests {
    @Test func buildsStepsFromSelectedOptions() {
        #expect(OnboardingFlow(includeAccount: false, includeFramework: false).steps == [.welcome, .allSet])
        #expect(OnboardingFlow(includeAccount: true, includeFramework: false).steps == [.welcome, .account, .allSet])
        #expect(OnboardingFlow(includeAccount: false, includeFramework: true).steps == [.welcome, .rulebook, .playbook, .allSet])
        #expect(OnboardingFlow(includeAccount: true, includeFramework: true).steps == [.welcome, .account, .rulebook, .playbook, .allSet])
    }

    @Test func returnsTheNextEnabledStep() {
        let flow = OnboardingFlow(includeAccount: false, includeFramework: true)

        #expect(flow.next(after: .welcome) == .rulebook)
        #expect(flow.next(after: .rulebook) == .playbook)
        #expect(flow.next(after: .playbook) == .allSet)
        #expect(flow.next(after: .allSet) == nil)
    }

    @Test func normalizesDraftFields() throws {
        let account = try OnboardingAccountDraft(
            name: "  Main Account  ",
            broker: "  Broker  ",
            balance: 12_500,
            currency: " gbp "
        ).normalized()
        let rule = try OnboardingRuleDraft(
            title: "  Protect Capital  ",
            category: "  Risk  ",
            checklistPrompt: "  Is risk defined?  ",
            description: "  Keep losses consistent.  "
        ).normalized()
        let setup = try OnboardingSetupDraft(
            name: "  Opening Range  ",
            strategy: "  Breakout  ",
            timeframe: "  5m  "
        ).normalized()

        #expect(account.name == "Main Account")
        #expect(account.broker == "Broker")
        #expect(account.currency == "GBP")
        #expect(rule.title == "Protect Capital")
        #expect(rule.category == "Risk")
        #expect(rule.checklistPrompt == "Is risk defined?")
        #expect(setup.name == "Opening Range")
        #expect(setup.strategy == "Breakout")
        #expect(setup.timeframe == "5m")
    }

    @Test func rejectsMissingRequiredFields() {
        #expect(throws: OnboardingDraftError.accountNameRequired) {
            try OnboardingAccountDraft().normalized()
        }
        #expect(throws: OnboardingDraftError.currencyRequired) {
            try OnboardingAccountDraft(name: "Live", currency: "US").normalized()
        }
        #expect(throws: OnboardingDraftError.ruleTitleRequired) {
            try OnboardingRuleDraft().normalized()
        }
        #expect(throws: OnboardingDraftError.setupNameRequired) {
            try OnboardingSetupDraft().normalized()
        }
    }

    @Test func detectsEditedDraftsForSkipConfirmation() {
        #expect(!OnboardingAccountDraft().isDirty)
        #expect(!OnboardingRuleDraft().isDirty)
        #expect(!OnboardingSetupDraft().isDirty)
        #expect(OnboardingAccountDraft(name: "Live").isDirty)
        #expect(OnboardingRuleDraft(checklistPrompt: "Wait for confirmation").isDirty)
        #expect(OnboardingSetupDraft(criteria: "Trend aligned").isDirty)
    }

    @Test func sessionPreservesSkipAndDiscardBehavior() {
        var session = OnboardingSession()
        session.start()

        #expect(session.currentStep == .account)

        session.accountDraft.name = "Unsaved Account"
        session.requestSkip()

        #expect(session.currentStep == .account)
        #expect(session.pendingDiscardStep == .account)

        session.discardAndAdvance()

        #expect(session.currentStep == .rulebook)
        #expect(session.accountResult == .skipped)
        #expect(session.accountDraft == OnboardingAccountDraft())
    }

    @Test func sessionRecordsCreatedItemsAndAdvances() {
        var session = OnboardingSession()
        session.start()
        session.markCreated(.account, name: "Live")

        #expect(session.accountResult == .created(name: "Live"))
        #expect(session.currentStep == .rulebook)
    }

    @MainActor
    @Test func savesExactlyOneModelForEachValidDraft() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let (_, account) = try OnboardingAccountDraft(name: "Live").makeModel()
        let (_, rule) = try OnboardingRuleDraft(title: "Define Risk").makeModel()
        let (_, setup) = try OnboardingSetupDraft(name: "Breakout").makeModel()

        context.insert(account)
        context.insert(rule)
        context.insert(setup)
        try context.save()

        #expect(try context.fetchCount(FetchDescriptor<Account>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<TradingRule>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<TradingSetup>()) == 1)
    }

    @MainActor
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            Account.self,
            ForexCalculation.self,
            Note.self,
            Stock.self,
            Trade.self,
            TradeAttachment.self,
            TradeContext.self,
            TradeFieldSuggestion.self,
            TradeLeg.self,
            TradeReview.self,
            TradeRuleCheck.self,
            TradeTransaction.self,
            TradeValueChangeLog.self,
            TradingRule.self,
            TradingSetup.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
