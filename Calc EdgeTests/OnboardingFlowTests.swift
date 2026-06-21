import Foundation
import SwiftData
import Testing
@testable import Calc_Edge

struct OnboardingFlowTests {
    @Test func defaultsFinalDestinationToJournal() {
        let session = OnboardingSession()

        #expect(session.selectedGoal == .journal)
        #expect(session.selectedGoal.rootTab == .journal)
    }

    @Test func buildsStepsFromSelectedOptions() {
        #expect(OnboardingFlow(includeAccount: false, includeFramework: false).steps == [.welcome, .allSet, .destination])
        #expect(OnboardingFlow(includeAccount: true, includeFramework: false).steps == [.welcome, .account, .allSet, .destination])
        #expect(OnboardingFlow(includeAccount: false, includeFramework: true).steps == [.welcome, .rulebook, .playbook, .allSet, .destination])
        #expect(OnboardingFlow(includeAccount: true, includeFramework: true).steps == [.welcome, .account, .rulebook, .playbook, .allSet, .destination])
    }

    @Test func returnsTheNextEnabledStep() {
        let flow = OnboardingFlow(includeAccount: false, includeFramework: true)

        #expect(flow.next(after: .welcome) == .rulebook)
        #expect(flow.next(after: .rulebook) == .playbook)
        #expect(flow.next(after: .playbook) == .allSet)
        #expect(flow.next(after: .allSet) == .destination)
        #expect(flow.next(after: .destination) == nil)
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

    @Test func skippingSetupMovesDirectlyToAllSetWithExpectedStatuses() {
        var defaultSession = OnboardingSession()
        defaultSession.skipSetup()

        #expect(defaultSession.currentStep == .allSet)
        #expect(defaultSession.accountResult == .skipped)
        #expect(defaultSession.ruleResult == .skipped)
        #expect(defaultSession.playbookResult == .skipped)
        #expect(defaultSession.accountID == nil)
        #expect(defaultSession.ruleID == nil)
        #expect(defaultSession.playbookID == nil)

        defaultSession.showDestination()
        #expect(defaultSession.currentStep == .destination)

        var disabledSession = OnboardingSession()
        disabledSession.includeAccountSetup = false
        disabledSession.includeFrameworkSetup = false
        disabledSession.skipSetup()

        #expect(disabledSession.currentStep == .allSet)
        #expect(disabledSession.accountResult == .notSelected)
        #expect(disabledSession.ruleResult == .notSelected)
        #expect(disabledSession.playbookResult == .notSelected)
    }

    @Test func finalDestinationMapsToSelectedRootTab() {
        var session = OnboardingSession()

        session.selectedGoal = .review
        #expect(session.selectedGoal.rootTab == .reviewCalendar)

        #if os(macOS)
        session.selectedGoal = .risk
        #expect(session.selectedGoal.rootTab == .stockCalc)
        session.selectedGoal = .forex
        #expect(session.selectedGoal.rootTab == .forexCalc)
        #endif
    }

    @Test func sessionRecordsCreatedItemsAndAdvances() {
        var session = OnboardingSession()
        let accountID = UUID()
        session.start()
        session.markCreated(.account, id: accountID, name: "Live")

        #expect(session.accountResult == .created(name: "Live"))
        #expect(session.accountID == accountID)
        #expect(session.currentStep == .rulebook)
    }

    @Test func sessionOnlyOffersEditingForCreatedItems() {
        var session = OnboardingSession()
        let accountID = UUID()
        session.selectedGoal = .review
        session.start()

        #expect(session.editTarget(for: .account) == nil)
        #expect(session.editTarget(for: .rulebook) == nil)

        session.accountDraft.name = "Live"
        session.markCreated(.account, id: accountID, name: "Live")

        guard case .account(let targetID, var editDraft) = session.editTarget(for: .account) else {
            Issue.record("Expected an account edit target")
            return
        }

        editDraft.name = "Changed but not applied"
        #expect(targetID == accountID)
        #expect(session.accountDraft.name == "Live")
        #expect(session.selectedGoal == .review)
    }

    @Test func sessionAppliesSuccessfulEditResults() {
        var session = OnboardingSession()
        let accountID = UUID()
        session.selectedGoal = .review
        session.start()
        session.accountDraft.name = "Live"
        session.markCreated(.account, id: accountID, name: "Live")

        let editedDraft = OnboardingAccountDraft(name: "Primary", currency: "GBP")
        session.apply(.account(id: accountID, draft: editedDraft))

        #expect(session.accountDraft == editedDraft)
        #expect(session.accountResult == .created(name: "Primary"))
        #expect(session.selectedGoal == .review)
    }

    @MainActor
    @Test func editingUpdatesExistingModelsWithoutCreatingDuplicates() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let saver = OnboardingSetupSaver()
        let account = try saver.saveAccount(OnboardingAccountDraft(name: "Live"), in: context)
        let rule = try saver.saveRule(OnboardingRuleDraft(title: "Define Risk"), in: context)
        let setup = try saver.saveSetup(OnboardingSetupDraft(name: "Breakout"), in: context)

        let editedAccount = try saver.updateAccount(
            id: account.id,
            with: OnboardingAccountDraft(name: "Primary", broker: "Broker", currency: "GBP"),
            in: context
        )
        let editedRule = try saver.updateRule(
            id: rule.id,
            with: OnboardingRuleDraft(title: "Always Define Risk", category: "Risk"),
            in: context
        )
        let editedSetup = try saver.updateSetup(
            id: setup.id,
            with: OnboardingSetupDraft(name: "A+ Breakout", timeframe: "5m"),
            in: context
        )

        #expect(try context.fetchCount(FetchDescriptor<Account>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<TradingRule>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<TradingSetup>()) == 1)
        #expect(editedAccount.name == "Primary")
        #expect(editedRule.title == "Always Define Risk")
        #expect(editedSetup.name == "A+ Breakout")

        #expect(try context.fetch(FetchDescriptor<Account>()).first?.accountName == "Primary")
        #expect(try context.fetch(FetchDescriptor<TradingRule>()).first?.title == "Always Define Risk")
        #expect(try context.fetch(FetchDescriptor<TradingSetup>()).first?.name == "A+ Breakout")
    }

    @MainActor
    @Test func invalidEditDoesNotChangeSavedModel() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let saver = OnboardingSetupSaver()
        let account = try saver.saveAccount(OnboardingAccountDraft(name: "Live"), in: context)

        #expect(throws: OnboardingDraftError.accountNameRequired) {
            try saver.updateAccount(
                id: account.id,
                with: OnboardingAccountDraft(name: "   "),
                in: context
            )
        }

        #expect(try context.fetch(FetchDescriptor<Account>()).first?.accountName == "Live")
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
