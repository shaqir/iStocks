//
//  iStocksUITestsLaunchTests.swift
//  iStocksUITests
//
//  Created by Sakir Saiyed
//
//  Captures a launch screenshot for each UI configuration. Useful as a smoke
//  test (the app must launch cleanly) and for visual regression review.
//

import XCTest

final class iStocksUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUp() {
        continueAfterFailure = false
    }

    func testLaunch() throws {
        let app = XCUIApplication()
        app.launchEnvironment["WATCHLIST_MODE"] = "mock"
        app.launch()

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
