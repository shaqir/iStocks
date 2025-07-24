//
//  EditWatchlistViewModelTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2025-07-23.
//

import Foundation
import XCTest
@testable import iStocks

final class EditWatchlistViewModelTests: XCTestCase {

    // MARK: - Setup

    var availableStocks: [Stock]!

    override func setUp() {
        super.setUp()
        availableStocks = MockStockData.allStocks
    }

    // MARK: - Validation Tests

    func test_emptyStockSelection_shouldThrowMustHaveOneError() {
        let vm = EditWatchlistViewModel(
            watchlist: Watchlist(id: UUID(), name: "My List", stocks: []),
            availableStocks: availableStocks
        )
        vm.name = "Valid Name"
        XCTAssertThrowsError(try vm.validateAndReturnWatchlist()) {
            XCTAssertEqual($0 as? StockValidationError, .mustHaveAtLeastOne)
        }
    }

    func test_duplicateName_shouldThrowDuplicateError() {
        let vm = EditWatchlistViewModel(
            watchlist: Watchlist(id: UUID(), name: "My List", stocks: [availableStocks.first!]),
            availableStocks: availableStocks
        )
        vm.name = "Tech Stocks"
        vm.existingNames = ["Tech Stocks", "Crypto"]
        XCTAssertThrowsError(try vm.validateAndReturnWatchlist()) {
            XCTAssertEqual($0 as? WatchlistValidationError, .duplicateName)
        }
    }

    func test_emptyName_shouldThrowValidationError() {
        let vm = EditWatchlistViewModel(watchlist: Watchlist(id: .init(), name: " ", stocks: []), availableStocks: availableStocks)
        XCTAssertThrowsError(try vm.validateAndReturnWatchlist()) { error in
            XCTAssertEqual(error as? WatchlistValidationError, .emptyName)
        }
    }

    func test_duplicateName_shouldThrowValidationError_caseInsensitive() {
        let vm = EditWatchlistViewModel(
            watchlist: Watchlist(id: .init(), name: "TECH", stocks: [availableStocks.first!]),
            availableStocks: availableStocks
        )
        vm.existingNames = ["Tech"]
        
        XCTAssertThrowsError(try vm.validateAndReturnWatchlist()) { error in
            XCTAssertEqual(error as? WatchlistValidationError, .duplicateName)
        }
    }

    func test_validWatchlist_shouldPassValidation() {
        let vm = EditWatchlistViewModel(watchlist: Watchlist(id: .init(), name: "New Watchlist", stocks: [availableStocks.first!]), availableStocks: availableStocks)
        vm.existingNames = ["Tech"]
        XCTAssertNoThrow(try vm.validateAndReturnWatchlist())
    }

    func test_trimmingName_shouldIgnoreLeadingTrailingSpaces() {
        let vm = EditWatchlistViewModel(
            watchlist: Watchlist(id: .init(), name: "   Tech ", stocks: [availableStocks.first!]),
            availableStocks: availableStocks
        )
        vm.existingNames = ["Tech"]
        
        XCTAssertThrowsError(try vm.validateAndReturnWatchlist()) { error in
            XCTAssertEqual(error as? WatchlistValidationError, .duplicateName)
        }
    }
    
    // MARK: - Limits

    func test_tooManyStocks_shouldThrowLimitError() {
        let tooMany = (0..<100).map {
            Stock(symbol: "SYM\($0)", name: "Stock \($0)", price: Double($0),
                  previousPrice: 0, isPriceUp: true, qty: 0, averageBuyPrice: 0,
                  sector: "Test", currency: "USD", exchange: "NYSE", isFavorite: false)
        }

        let vm = EditWatchlistViewModel(
            watchlist: Watchlist(id: UUID(), name: "Limit Test", stocks: tooMany),
            availableStocks: tooMany
        )
        vm.name = "Limit Test"
        vm.selectedStocks = tooMany

        XCTAssertThrowsError(try vm.validateAndReturnWatchlist()) {
            XCTAssertEqual($0 as? StockValidationError, .limitReached(num: AppConstants.maxStocksPerWatchlist))
        }
    }
    
    func test_exceedingStockLimit_shouldThrowError() {
           let stocks = (0..<100).map { i in
               Stock(symbol: "SYM\(i)", name: "Dummy \(i)", price: 1.0, previousPrice: 0, isPriceUp: true, qty: 0, averageBuyPrice: 0, sector: "Tech", currency: "USD", exchange: "NYSE", isFavorite: false)
           }
           let vm = EditWatchlistViewModel(watchlist: Watchlist(id: .init(), name: "Limit Test", stocks: []), availableStocks: stocks)
           vm.selectedStocks = stocks
           vm.existingNames = []

           XCTAssertThrowsError(try vm.validateAndReturnWatchlist()) { error in
               guard let error = error as? StockValidationError else {
                   XCTFail("Unexpected error type")
                   return
               }
               XCTAssertEqual(error, .limitReached(num: AppConstants.maxStocksPerWatchlist))
           }
       }

    // MARK: - Behavior

    func test_validWatchlist_shouldReturnValidatedWatchlist() throws {
        let vm = EditWatchlistViewModel(
            watchlist: Watchlist(id: UUID(), name: "Growth", stocks: [availableStocks.first!]),
            availableStocks: availableStocks
        )
        vm.name = "New Watchlist"
        vm.selectedStocks = [availableStocks.first!]

        let result = try vm.validateAndReturnWatchlist()
        XCTAssertEqual(result.name, "New Watchlist")
        XCTAssertEqual(result.stocks.count, 1)
    }
    
    // MARK: - Stock Selection Tests

    func test_addStock_shouldBeInSelectedStocks() {
        let stock = availableStocks.first!
        let vm = EditWatchlistViewModel(watchlist: Watchlist(id: .init(), name: "Test", stocks: []), availableStocks: availableStocks)
        vm.toggleStock(stock)
        XCTAssertTrue(vm.selectedStocks.contains(stock))
    }

    func test_removeStock_shouldNotBeInSelectedStocks() {
        let stock = availableStocks.first!
        let watchlist = Watchlist(id: .init(), name: "Test", stocks: [stock])
        let vm = EditWatchlistViewModel(watchlist: watchlist, availableStocks: availableStocks)
        vm.toggleStock(stock) // deselect
        XCTAssertFalse(vm.selectedStocks.contains(stock))
    }

    func test_filterStocks_shouldMatchSymbolOrName_caseInsensitive() {
        let vm = EditWatchlistViewModel(watchlist: Watchlist(id: .init(), name: "Test", stocks: []), availableStocks: availableStocks)
        vm.searchText = "aapl"
        let result = vm.filteredStocks
        XCTAssertTrue(result.contains { $0.symbol.lowercased() == "aapl" })
    }

    func test_uniqueStocks_shouldContainOnlyOneInstancePerSymbol() {
        let duplicate = availableStocks.first!
        let withDuplicates = availableStocks + [duplicate, duplicate]
        
        let vm = EditWatchlistViewModel(
            watchlist: Watchlist(id: .init(), name: "Unique", stocks: []),
            availableStocks: withDuplicates
        )
        
        let uniqueStocks = vm.uniqueStocks(from: withDuplicates)
        let uniqueSymbols = Set(uniqueStocks.map { $0.symbol })

        XCTAssertEqual(uniqueSymbols.count, uniqueStocks.count, "Each stock symbol should be unique after deduplication.")
    }
    
    // MARK: - Filtered Stocks

    func test_filteredStocks_shouldMatchSearchText() {
        let vm = EditWatchlistViewModel(
            watchlist: Watchlist(id: UUID(), name: "FilterTest", stocks: []),
            availableStocks: MockStockData.allStocks
        )
        vm.searchText = "AAPL"

        let result = vm.filteredStocks
        XCTAssertTrue(result.allSatisfy { $0.symbol.localizedCaseInsensitiveContains("AAPL") || $0.name.localizedCaseInsensitiveContains("AAPL") })
    }

    func test_filteredStocks_shouldReturnAllIfSearchTextEmpty() {
        let vm = EditWatchlistViewModel(
            watchlist: Watchlist(id: UUID(), name: "FilterTest", stocks: []),
            availableStocks: MockStockData.allStocks
        )
        vm.searchText = ""

        XCTAssertEqual(vm.filteredStocks.count, MockStockData.allStocks.count)
    }
    
}
