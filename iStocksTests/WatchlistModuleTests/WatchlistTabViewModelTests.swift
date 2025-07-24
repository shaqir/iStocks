//
//  WatchlistTabViewModelTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2025-07-23.
//

import Foundation
import XCTest
import Combine
@testable import iStocks
 
final class WatchlistTabViewModelTests: XCTestCase {

    var sut: WatchlistTabViewModel!
    var mockPersistence: MockWatchlistPersistenceService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockPersistence = MockWatchlistPersistenceService()
        sut = WatchlistTabViewModel(persistenceService: mockPersistence, availableStocks: MockStockData.allStocks)
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        mockPersistence = nil
        super.tearDown()
    }

    func test_init_shouldLoadWatchlists() {
        let names = sut.watchlists.map { $0.name }
        XCTAssertTrue(names.contains("Tech"))
        XCTAssertTrue(names.contains("Energy"))
    }

    func test_addWatchlist_shouldAppendNewWatchlist() {
        let initialCount = sut.watchlists.count
        let newWatchlist = Watchlist(id: UUID(), name: "Finance", stocks: [])
        sut.addWatchlist(newWatchlist)
        XCTAssertEqual(sut.watchlists.count, initialCount + 1)
        XCTAssertTrue(sut.watchlists.contains(where: { $0.name == "Finance" }))
    }

    func test_removeWatchlist_shouldRemoveCorrectOne() {
        let toRemove = sut.watchlists.first!
        sut.removeWatchlist(toRemove)
        XCTAssertFalse(sut.watchlists.contains(where: { $0.id == toRemove.id }))
    }

    func test_updateWatchlist_shouldUpdateDataCorrectly() {
        var toUpdate = sut.watchlists.first!
        toUpdate.name = "Updated"
        sut.updateWatchlist(toUpdate)
        XCTAssertTrue(sut.watchlists.contains(where: { $0.name == "Updated" }))
    }

    func test_watchlistViewModels_shouldBeInSyncWithWatchlists() {
        XCTAssertEqual(sut.watchlists.count, sut.watchlistViewModels.count)
    }

    func test_selectedIndex_shouldChangeOnTabChange() {
        sut.selectedIndex = 1
        XCTAssertEqual(sut.selectedIndex, 1)
    }

    func test_getSelectedWatchlist_shouldReturnCorrectItem() {
        let selected = sut.getSelectedWatchlist()
        XCTAssertEqual(selected.id, sut.watchlists[sut.selectedIndex].id)
    }

    func test_replaceWatchlists_shouldReplaceAll() {
        let newList = Watchlist(id: UUID(), name: "New One", stocks: [])
        sut.replaceWatchlists([newList])
        XCTAssertEqual(sut.watchlists.count, 1)
        XCTAssertEqual(sut.watchlists.first?.name, "New One")
    }

    func test_refreshAll_shouldTriggerRefreshRequested() {
        let expectation = XCTestExpectation(description: "Refresh triggered")

        let vm = sut.watchlistViewModels.first!
        vm.refreshRequested
            .sink { _ in expectation.fulfill() }
            .store(in: &cancellables)

        sut.refreshAll()
        wait(for: [expectation], timeout: 1.0)
    }
}
 

