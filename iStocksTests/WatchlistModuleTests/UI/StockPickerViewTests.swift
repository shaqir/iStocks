//
//  StockPickerViewTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2025-07-24.
//

import Foundation
import XCTest
import SwiftUI
@testable import iStocks

@MainActor
final class StockPickerViewTests: XCTestCase {

    var viewModel: EditWatchlistViewModel!
    var selected: [Stock]!

    override func setUp() async throws {
        try await super.setUp()
        selected = [MockStockData.allStocks[0]]
        viewModel = EditWatchlistViewModel(
            watchlist: Watchlist(id: UUID(), name: "Test", stocks: selected),
            availableStocks: MockStockData.allStocks
        )
    }

    func testSearchBarUpdatesSearchText() {
        viewModel.searchText = "Apple"
        XCTAssertEqual(viewModel.searchText, "Apple")
    }

    func testInfoBannerDisplaysCorrectCount() {
        XCTAssertEqual(viewModel.selectedStocks.count, selected.count)
    }

    func testTappingStockTogglesSelection() {
        let viewModel = EditWatchlistViewModel(
            watchlist: Watchlist(id: UUID(), name: "Test Watchlist", stocks: []),
            availableStocks: MockStockData.allStocks
        )

        let stockToSelect = MockStockData.allStocks[1]
        viewModel.addStock(stockToSelect)

        XCTAssertTrue(viewModel.selectedStocks.contains(stockToSelect))
    }
}
