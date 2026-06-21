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
    func testGuidedOnboardingCanSkipToAllSet() throws {
        let app = XCUIApplication()
        app.launch()

        let continueButton = app.buttons["onboarding.continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
        continueButton.click()

        for step in ["account", "rulebook", "playbook"] {
            XCTAssertTrue(app.otherElements["onboarding.step.\(step)"].waitForExistence(timeout: 3))
            app.buttons["onboarding.skip"].click()
        }

        XCTAssertTrue(app.otherElements["onboarding.step.allSet"].waitForExistence(timeout: 3))
        app.buttons["onboarding.finish"].click()
        XCTAssertTrue(app.staticTexts["Journal"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testEditedOnboardingDraftRequiresDiscardConfirmation() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["onboarding.continue"].waitForExistence(timeout: 5))
        app.buttons["onboarding.continue"].click()

        let nameField = app.textFields["onboarding.account.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.click()
        nameField.typeText("Test Account")
        app.buttons["onboarding.skip"].click()

        XCTAssertTrue(app.buttons["Discard & Continue"].waitForExistence(timeout: 3))
        app.buttons["Keep Editing"].click()
        XCTAssertTrue(app.otherElements["onboarding.step.account"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
