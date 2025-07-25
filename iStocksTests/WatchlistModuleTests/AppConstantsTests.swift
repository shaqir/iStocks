//
//  AppConstantsTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2025-07-24.
//

import Foundation
import XCTest
@testable import iStocks

final class AppConstantsTests: XCTestCase {

    func test_maxStocksPerWatchlist_shouldBeValid() {
        XCTAssertGreaterThan(AppConstants.maxStocksPerWatchlist, 0)
        XCTAssertLessThanOrEqual(AppConstants.maxStocksPerWatchlist, 100)
    }

    func test_maxWatchlists_shouldBeValid() {
        XCTAssertGreaterThan(AppConstants.maxWatchlists, 0)
        XCTAssertLessThanOrEqual(AppConstants.maxWatchlists, 20)
    }
}
