//
//  Calc_EdgeUITests.swift
//  Calc EdgeUITests
//
//  Created by Marcus Gardner on 11/01/2026.
//

import XCTest

final class Calc_EdgeUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testGuidedOnboardingCanSkipToReview() throws {
        let app = launchOnboardingApp()

        let continueButton = app.buttons["onboarding.continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.activateForTest()

        for step in ["account", "rulebook", "playbook"] {
            XCTAssertTrue(app.element("onboarding.step.\(step)").waitForExistence(timeout: 5))
            app.buttons["onboarding.skip"].activateForTest()
        }

        XCTAssertTrue(app.element("onboarding.step.review").waitForExistence(timeout: 5))
        app.buttons["onboarding.review.continue"].activateForTest()
        XCTAssertTrue(app.element("onboarding.step.destination").waitForExistence(timeout: 5))
        app.buttons["onboarding.destination.back"].activateForTest()
        XCTAssertTrue(app.element("onboarding.step.review").waitForExistence(timeout: 5))
        app.buttons["onboarding.review.continue"].activateForTest()
        app.buttons["onboarding.finish"].activateForTest()
        XCTAssertTrue(app.staticTexts["Journal"].waitForExistence(timeout: 5))

        app.terminate()
        app.launchEnvironment.removeValue(forKey: "CALC_EDGE_UI_TEST_RESET_ONBOARDING")
        app.launch()
        XCTAssertTrue(app.staticTexts["Journal"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.element("onboarding.step.welcome").exists)
    }

    @MainActor
    func testNotNowConfirmsBeforeGoingDirectlyToDestination() throws {
        let app = launchOnboardingApp()

        XCTAssertTrue(app.buttons["Not now"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Skip onboarding"].exists)
        app.buttons["Not now"].activateForTest()

        let confirmButton = app.buttons["onboarding.confirmWithoutSetup"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["You can add accounts, rules, and trading setups later from the app."].exists)
        confirmButton.activateForTest()

        XCTAssertTrue(app.element("onboarding.step.destination").waitForExistence(timeout: 5))
        XCTAssertFalse(app.element("onboarding.step.review").exists)

        app.buttons["onboarding.destination.back"].activateForTest()
        XCTAssertTrue(app.element("onboarding.step.welcome").waitForExistence(timeout: 5))
    }

    @MainActor
    func testStockDestinationUsesLeafRouteAndTitle() throws {
        let app = launchOnboardingApp()

        XCTAssertTrue(app.buttons["Not now"].waitForExistence(timeout: 5))
        app.buttons["Not now"].activateForTest()
        XCTAssertTrue(app.buttons["onboarding.confirmWithoutSetup"].waitForExistence(timeout: 3))
        app.buttons["onboarding.confirmWithoutSetup"].activateForTest()

        let riskDestination = app.buttons["onboarding.destination.risk"]
        XCTAssertTrue(riskDestination.waitForExistence(timeout: 3))
        riskDestination.activateForTest()

        let finishButton = app.buttons["onboarding.finish"]
        XCTAssertEqual(finishButton.label, "Open Stock Calc")
        finishButton.activateForTest()

        XCTAssertTrue(app.staticTexts["Stock Calc"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testContinueWithNoOptionsConfirmsBeforeSkippingSetup() throws {
        let app = launchOnboardingApp()

        let accountToggle = app.switches["onboarding.includeAccount"]
        let frameworkToggle = app.switches["onboarding.includeFramework"]
        XCTAssertTrue(accountToggle.waitForExistence(timeout: 5))
        XCTAssertTrue(frameworkToggle.waitForExistence(timeout: 5))

        accountToggle.activateForTest()
        frameworkToggle.activateForTest()
        app.buttons["onboarding.continue"].activateForTest()

        XCTAssertTrue(app.buttons["onboarding.confirmWithoutSetup"].waitForExistence(timeout: 3))
        app.buttons["onboarding.confirmWithoutSetup"].activateForTest()
        XCTAssertTrue(app.element("onboarding.step.destination").waitForExistence(timeout: 5))
        XCTAssertFalse(app.element("onboarding.step.review").exists)
    }

    @MainActor
    func testRequiredFieldValidationAppearsInline() throws {
        let app = launchOnboardingApp()

        XCTAssertTrue(app.buttons["onboarding.continue"].waitForExistence(timeout: 5))
        app.buttons["onboarding.continue"].activateForTest()
        XCTAssertTrue(app.element("onboarding.step.account").waitForExistence(timeout: 5))
        app.buttons["onboarding.save"].activateForTest()

        XCTAssertTrue(
            app.staticTexts["Enter an account name before continuing."]
                .waitForExistence(timeout: 3)
        )
    }

    @MainActor
    func testEditedOnboardingDraftRequiresDiscardConfirmation() throws {
        let app = launchOnboardingApp()

        XCTAssertTrue(app.buttons["onboarding.continue"].waitForExistence(timeout: 5))
        app.buttons["onboarding.continue"].activateForTest()

        let nameField = app.textFields["onboarding.account.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.activateForTest()
        nameField.typeText("Test Account")
        app.buttons["onboarding.skip"].activateForTest()

        XCTAssertTrue(app.sheets.buttons["Discard & Continue"].waitForExistence(timeout: 3))
        app.sheets.buttons["Keep Editing"].activateForTest()
        XCTAssertTrue(app.element("onboarding.step.account").exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    @MainActor
    private func launchOnboardingApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["CALC_EDGE_UI_TEST_RESET_ONBOARDING"] = "1"
        app.launch()
        return app
    }
}

private extension XCUIElement {
    func activateForTest() {
        #if os(macOS)
        click()
        #else
        tap()
        #endif
    }
}

private extension XCUIApplication {
    func element(_ identifier: String) -> XCUIElement {
        descendants(matching: .any)[identifier]
    }
}
