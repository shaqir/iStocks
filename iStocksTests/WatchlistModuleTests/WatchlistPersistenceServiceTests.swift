//
//  WatchlistPersistenceTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2025-07-22.
//

import Foundation
import XCTest
import SwiftData
@testable import iStocks

final class WatchlistPersistenceServiceTests: XCTestCase {

    private func makeInMemoryContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: WatchlistEntity.self, configurations: config)
        return ModelContext(container)
    }

    private func makeService() throws -> WatchlistPersistenceService {
        let context = try makeInMemoryContext()
        return WatchlistPersistenceService(context: context)
    }

    private func mockWatchlist(name: String = "Test List") -> Watchlist {
        Watchlist(id: UUID(), name: name, stocks: MockStockData.allStocks.prefix(2).map { $0 })
    }

    func test_saveWatchlist_shouldPersistSuccessfully() throws {
        let service = try makeService()
        let watchlist = mockWatchlist()

        service.saveWatchlist(watchlist)

        let loaded = service.loadWatchlists()
        XCTAssertTrue(loaded.contains(where: { $0.name == watchlist.name }))
    }

    func test_loadAll_shouldReturnPreviouslySavedWatchlists() throws {
        let service = try makeService()

        let list1 = mockWatchlist(name: "List One")
        let list2 = mockWatchlist(name: "List Two")

        service.saveWatchlist(list1)
        service.saveWatchlist(list2)

        let all = service.loadWatchlists()
        let names = all.map { $0.name }

        XCTAssertTrue(names.contains("List One"))
        XCTAssertTrue(names.contains("List Two"))
    }

    func test_deleteWatchlist_shouldRemoveIt() throws {
        let service = try makeService()
        let list = mockWatchlist(name: "ToDelete")

        service.saveWatchlist(list)
        service.deleteWatchlist(list)

        let all = service.loadWatchlists()
        XCTAssertFalse(all.contains(where: { $0.name == "ToDelete" }))
    }

    func test_updateWatchlist_shouldReflectChanges() throws {
        let service = try makeService()
        var original = mockWatchlist(name: "Original")
        service.saveWatchlist(original)

        original.name = "Updated Name"
        service.saveWatchlist(original)

        let all = service.loadWatchlists()
        XCTAssertTrue(all.contains(where: { $0.name == "Updated Name" }))
    }

    func test_replaceAll_shouldOnlyPersistNewWatchlists() throws {
        let service = try makeService()

        let list1 = mockWatchlist(name: "Old One")
        let list2 = mockWatchlist(name: "Old Two")
        service.saveWatchlist(list1)
         service.saveWatchlist(list2)

        let newList = mockWatchlist(name: "Fresh Start")
        service.replaceAll(with: [newList])

        let all = service.loadWatchlists()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.name, "Fresh Start")
    }

    func test_multipleOperations_shouldMaintainIntegrity() throws {
        let service = try makeService()

        let listA = mockWatchlist(name: "Alpha")
        let listB = mockWatchlist(name: "Beta")
        let listC = mockWatchlist(name: "Gamma")

        service.saveWatchlists([listA, listB, listC])
        service.deleteWatchlist(listB)

        var modifiedC = listC
        modifiedC.name = "Delta"
        service.saveWatchlist(modifiedC)

        let all = service.loadWatchlists()
        XCTAssertEqual(all.count, 2)
        XCTAssertTrue(all.contains { $0.name == "Alpha" })
        XCTAssertTrue(all.contains { $0.name == "Delta" })
    }
    
}
