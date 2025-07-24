//
//  WatchlistViewModelTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2025-07-22.
//

import Foundation
import XCTest
import Combine
@testable import iStocks

final class WatchlistViewModelTests: XCTestCase {

    private var cancellables: Set<AnyCancellable> = []

    private func makeViewModel() -> WatchlistViewModel {
        let watchlist = Watchlist(id: UUID(), name: "Tech", stocks: MockStockData.allStocks.prefix(3).map { $0 })
        let available = MockStockData.allStocks
        return WatchlistViewModel(watchlist: watchlist, availableStocks: available)
    }

    // MARK: - Initialization

    func test_init_shouldInitializeCorrectly() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.watchlist.name, "Tech")
        XCTAssertEqual(vm.selectedStocks.count, 3)
    }

    // MARK: - Stock Selection

    func test_isSelected_shouldReturnTrueForExistingStock() {
        let vm = makeViewModel()
        let stock = vm.selectedStocks.first!
        XCTAssertTrue(vm.isSelected(stock))
    }

    func test_isSelected_shouldReturnFalseForNonExistingStock() {
        let vm = makeViewModel()
        let stock = Stock.mock(symbol: "XYZ")
        XCTAssertFalse(vm.isSelected(stock))
    }

    // MARK: - Add Stock

    func test_addStock_shouldAddAndSync() {
        let vm = makeViewModel()
        let newStock = MockStockData.allStocks.last!

        let expect = expectation(description: "Watchlist updated")
        vm.watchlistStructuralUpdate
            .sink { updated in
                XCTAssertTrue(updated.stocks.contains(where: { $0.symbol == newStock.symbol }))
                expect.fulfill()
            }
            .store(in: &cancellables)

        vm.addStock(newStock)
        wait(for: [expect], timeout: 1.0)
    }

    // MARK: - Remove Stock

    func test_removeStock_shouldRemoveAndSync() {
        let vm = makeViewModel()
        let toRemove = vm.selectedStocks.first!

        let expect = expectation(description: "Stock removed and parent synced")
        vm.watchlistStructuralUpdate
            .sink { updated in
                XCTAssertFalse(updated.stocks.contains(toRemove))
                expect.fulfill()
            }
            .store(in: &cancellables)

        vm.removeStock(toRemove)
        wait(for: [expect], timeout: 1.0)
    }

    // MARK: - Replace Stock Prices

    func test_replaceStocks_shouldOnlyUpdateChangedPrices() {
        let vm = makeViewModel()
        let updated = vm.selectedStocks.map {
            Stock(symbol: $0.symbol, name: $0.name, price: $0.price + 5.0, previousPrice: $0.price, isPriceUp: true, qty: 0, averageBuyPrice: 0, sector: $0.sector, currency: "USD", exchange: "NSE", isFavorite: false)
        }

        let expect = expectation(description: "Prices replaced and priceUpdate emitted")
        vm.priceUpdate
            .sink { updated in
                XCTAssertEqual(updated.count, 3)
                expect.fulfill()
            }
            .store(in: &cancellables)

        vm.replaceStocks(updated)
        wait(for: [expect], timeout: 1.0)
    }

    // MARK: - Sync With Parent

    func test_syncWithParent_shouldEmitCurrentWatchlist() {
        let vm = makeViewModel()

        let expect = expectation(description: "Emits current watchlist")
        vm.watchlistStructuralUpdate
            .sink { updated in
                XCTAssertEqual(updated.id, vm.watchlist.id)
                expect.fulfill()
            }
            .store(in: &cancellables)

        vm.syncWithParent()
        wait(for: [expect], timeout: 1.0)
    }

    // MARK: - Search Filtering

    func test_filteredStocks_shouldReturnMatchingResults() {
        let vm = makeViewModel()
        let knownSymbol = vm.selectedStocks.first!.symbol
        vm.searchText = knownSymbol

        let filtered = vm.filteredStocks
        XCTAssertTrue(filtered.contains(where: { $0.symbol == knownSymbol }))
    }

    func test_filteredStocks_shouldReturnAllIfEmptySearch() {
        let vm = makeViewModel()
        vm.searchText = ""
        XCTAssertEqual(vm.filteredStocks.count, vm.selectedStocks.count)
    }

    // MARK: - Refresh Trigger

    func test_requestRefresh_shouldEmitSignal() {
        let vm = makeViewModel()
        let expect = expectation(description: "Refresh requested")
        vm.refreshRequested
            .sink {
                expect.fulfill()
            }
            .store(in: &cancellables)

        vm.requestRefresh()
        wait(for: [expect], timeout: 1.0)
    }
}
