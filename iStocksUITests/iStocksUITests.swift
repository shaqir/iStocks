//
//  iStocksUITests.swift
//  iStocksUITests
//
//  Created by Sakir Saiyed
//
//  End-to-end UI flows driven through the accessibility identifiers defined in
//  `AccessibilityID` (Core/Accessibility/AccessibilityIdentifiers.swift).
//
//  Determinism: the app is launched with WATCHLIST_MODE=mock so no network/API
//  keys are required and the watchlist populates instantly. On the simulator the
//  biometric AuthGate is skipped (see iStocksApp.swift), so flows start at the
//  TabBarContainer.
//

import XCTest

final class iStocksUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["WATCHLIST_MODE"] = "mock"
        app.launch()
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    // MARK: - Tab bar

    /// All five tabs render with their deterministic identifiers
    /// (`tab_watchlist` … `tab_settings` from `AccessibilityID.Tabs`).
    func testTabBar_showsAllTabs() {
        for tab in ["watchlist", "orders", "portfolio", "research", "settings"] {
            let id = AccessibilityID.Tabs.identifier(tab)
            XCTAssertTrue(
                app.buttons[id].waitForExistence(timeout: 5),
                "Expected tab button '\(id)' to exist"
            )
        }
    }

    /// Round-trips between two tabs and verifies the selected one stays hittable.
    func testTabSwitching_roundTripsBetweenTabs() {
        let research = app.buttons[AccessibilityID.Tabs.identifier("research")]
        let portfolio = app.buttons[AccessibilityID.Tabs.identifier("portfolio")]

        XCTAssertTrue(research.waitForExistence(timeout: 5))
        research.tap()

        XCTAssertTrue(portfolio.waitForExistence(timeout: 5))
        portfolio.tap()
        XCTAssertTrue(portfolio.isHittable)
    }

    // MARK: - Watchlist

    /// Switching to the Watchlist tab loads a *populated* watchlist — asserted via
    /// the presence of at least one stock row (`watchlist_stock_row`), which only
    /// exists once mock data has been grouped into watchlists and rendered.
    /// Rows use `.accessibilityElement(children: .combine)`, so query type-agnostically.
    func testWatchlist_populatesAfterSwitchingTab() {
        app.buttons[AccessibilityID.Tabs.identifier("watchlist")].tap()

        let firstRow = app.descendants(matching: .any)
            .matching(identifier: AccessibilityID.Watchlist.stockRow)
            .firstMatch
        XCTAssertTrue(
            firstRow.waitForExistence(timeout: 8),
            "Watchlist did not populate (no stock rows rendered)"
        )
    }

    /// The search field accepts input — exercises the filter entry point
    /// (`watchlist_search_field`).
    func testWatchlist_searchFieldAcceptsInput() {
        app.buttons[AccessibilityID.Tabs.identifier("watchlist")].tap()

        let search = app.textFields[AccessibilityID.Watchlist.searchField]
        guard search.waitForExistence(timeout: 8) else {
            XCTFail("Search field '\(AccessibilityID.Watchlist.searchField)' not found")
            return
        }

        search.tap()
        search.typeText("AAPL")
        XCTAssertEqual(search.value as? String, "AAPL")
    }
}
