//
//  SakinahUITests.swift
//  SakinahUITests
//
//  Created by Rork on April 18, 2026.
//

import XCTest

final class SakinahUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it's important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testTrueMaxLaunchesWithoutAuthentication() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 8))
        XCTAssertFalse(app.textFields["Email"].exists)
        XCTAssertFalse(app.secureTextFields["Password"].exists)
        XCTAssertFalse(app.buttons["truemax.skipOnboarding"].exists)
        XCTAssertFalse(app.buttons["Play 55-second walkthrough"].exists)
    }

    @MainActor
    func testMarketingWalkthroughLauncherIsRecordReady() throws {
        let app = XCUIApplication()
        app.launchArguments.append("-TrueMaxMarketingDemo")
        app.launch()

        let playButton = app.buttons["Play 55-second walkthrough"]
        XCTAssertTrue(playButton.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["Explore on my own"].exists)
        XCTAssertTrue(app.staticTexts["SEE TRUEMAX IN ACTION"].exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
