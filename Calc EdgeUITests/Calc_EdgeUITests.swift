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
        let app = XCUIApplication()
        app.launch()

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
    }

    @MainActor
    func testSkippingSetupGoesDirectlyToDestinationAndBackToWelcome() throws {
        let app = XCUIApplication()
        app.launch()

        let skipButton = app.buttons["Skip onboarding"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 5))
        skipButton.activateForTest()

        XCTAssertTrue(app.element("onboarding.step.destination").waitForExistence(timeout: 5))
        XCTAssertFalse(app.element("onboarding.step.review").exists)

        app.buttons["onboarding.destination.back"].activateForTest()
        XCTAssertTrue(app.element("onboarding.step.welcome").waitForExistence(timeout: 5))
    }

    @MainActor
    func testStockDestinationUsesLeafRouteAndTitle() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["Skip onboarding"].waitForExistence(timeout: 5))
        app.buttons["Skip onboarding"].activateForTest()

        let riskDestination = app.buttons["onboarding.destination.risk"]
        XCTAssertTrue(riskDestination.waitForExistence(timeout: 3))
        riskDestination.activateForTest()

        let finishButton = app.buttons["onboarding.finish"]
        XCTAssertEqual(finishButton.label, "Open Stock Calc")
        finishButton.activateForTest()

        XCTAssertTrue(app.staticTexts["Stock Calc"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testRequiredFieldValidationAppearsInline() throws {
        let app = XCUIApplication()
        app.launch()

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
        let app = XCUIApplication()
        app.launch()

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
