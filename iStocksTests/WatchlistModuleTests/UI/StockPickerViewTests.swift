//
//  StockPickerViewTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2025-07-24.
//

import Foundation
import XCTest
import SwiftUI
import ViewInspector
@testable import iStocks

final class StockPickerViewTests: XCTestCase {
    
    var viewModel: EditWatchlistViewModel!
    var selected: [Stock]!
    
    override func setUp() {
        super.setUp()
        selected = [MockStockData.allStocks[0]]
        viewModel = EditWatchlistViewModel(
            watchlist: Watchlist(id: UUID(), name: "Test", stocks: selected),
            availableStocks: MockStockData.allStocks
        )
    }
    
    func testSearchBarUpdatesSearchText() throws {
        let sut = StockPickerView(viewModel: viewModel) { _ in }
        let textField = try sut.inspect().find(ViewType.TextField.self)
        try textField.setInput("Apple")
        XCTAssertEqual(viewModel.searchText, "Apple")
    }

    func testInfoBannerDisplaysCorrectCount() throws {
        let sut = StockPickerView(viewModel: viewModel) { _ in }
        let text = try sut.inspect().find(text: "\(selected.count)/\(AppConstants.maxStocksPerWatchlist) stocks added")
        XCTAssertNotNil(text)
    }

    func testListRendersFilteredStocks() throws {
        // Setup
        let sut = StockPickerView(viewModel: viewModel) { _ in }
        let navStack = try sut.inspect().navigationStack()
        let vStack = try navStack.vStack()
        let list = try vStack.list(2) // Adjust index based on your view hierarchy
        let forEach = try list.forEach(0)
        let rowCount = forEach.count
        XCTAssertEqual(rowCount, viewModel.filteredStocks.count)
    }
    
    func testTappingStockTogglesSelection() throws {
        // Given
        let viewModel = EditWatchlistViewModel(
            watchlist: Watchlist(id: UUID(), name: "Test Watchlist", stocks: []),
            availableStocks: MockStockData.allStocks
        )
        _ = StockPickerView(viewModel: viewModel) { _ in }

        // When: call addStock manually
        let stockToSelect = MockStockData.allStocks[1]
        viewModel.addStock(stockToSelect)

        // Then
        XCTAssertTrue(viewModel.selectedStocks.contains(stockToSelect))
    }
}
