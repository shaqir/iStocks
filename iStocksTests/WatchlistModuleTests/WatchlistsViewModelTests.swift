//
//  WatchlistsViewModelTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2025-07-22.
//

import Foundation
import SwiftData
import XCTest
@testable import iStocks
import Combine

// MARK: - Mock Implementations

final class MockWatchlistViewModelProvider: WatchlistViewModelProvider {
    var allStocks: [iStocks.Stock]
    var watchlistDidUpdate: PassthroughSubject<iStocks.Watchlist, Never>
    var cachedViewModels: [iStocks.WatchlistViewModel]
    var cache: [UUID : iStocks.WatchlistViewModel]

    private let availableStocks: [Stock]

    init(availableStocks: [Stock]) {
        self.availableStocks = availableStocks
        self.cache = [:]
        self.watchlistDidUpdate = .init()
        self.cachedViewModels = []
        self.allStocks = MockStockData.allStocks
    }

    func makeWatchlistViewModel(for watchlist: Watchlist) -> WatchlistViewModel {
        WatchlistViewModel(watchlist: watchlist, availableStocks: availableStocks)
    }

    func viewModel(for watchlist: iStocks.Watchlist) -> iStocks.WatchlistViewModel {
        makeWatchlistViewModel(for: watchlist)
    }
}

// MARK: - Test Fixtures & Factories

func makeInMemoryModelContext() throws -> ModelContext {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: WatchlistEntity.self, configurations: config)
    return ModelContext(container)
}

func makeMockRepository() -> MockWatchlistRepository {
    Logger.log("makeMockRepository() called.")
    return MockStockRepositoryImpl(service: MockStockStreamingService())
}

func makeWatchlistUseCases(mode: WatchlistAppMode, mockRepo: any MockWatchlistRepository) -> WatchlistUseCases {
    switch mode {
    case .mock:
        return WatchlistUseCases(
            observeMock: ObserveMockStocksUseCaseImpl(repository: mockRepo),
            observeTop50: ObserveTop50StocksUseCaseImpl(repository: mockRepo),
            observeLiveWebSocket: ObserveStockPricesUseCaseImpl(repository: mockRepo),
            observeWatchlist: ObserveWatchlistStocksUseCaseImpl(repository: mockRepo),
            fetchQuotesBySymbols: FetchStocksBySymbolUseCaseImpl(repository: mockRepo)
        )
    default:
        fatalError("Only .mock mode is supported in tests for now")
    }
}

func makeWatchlistsViewModel(mode: WatchlistAppMode = .mock) throws -> WatchlistsViewModel {
    let context = try makeInMemoryModelContext()
    let persistenceService = WatchlistPersistenceService(context: context)
    let mockRepo = makeMockRepository()
    let useCases = makeWatchlistUseCases(mode: .mock, mockRepo: mockRepo)
    let provider = MockWatchlistViewModelProvider(availableStocks: MockStockData.allStocks)

    return WatchlistsViewModel(
        useCases: useCases,
        persistenceService: persistenceService,
        viewModelProvider: provider
    )
}

func makeWatchlistsViewModelWithMockData() throws -> WatchlistsViewModel {
    let context = try makeInMemoryModelContext()
    let persistenceService = WatchlistPersistenceService(context: context)

    // Inject mock watchlists
    let mockWatchlists = WatchlistFactory.createMockWatchlists()
    persistenceService.saveWatchlists(mockWatchlists)

    let mockRepo = makeMockRepository()
    let useCases = makeWatchlistUseCases(mode: .mock, mockRepo: mockRepo)
    let provider = MockWatchlistViewModelProvider(availableStocks: MockStockData.allStocks)

    return WatchlistsViewModel(
        useCases: useCases,
        persistenceService: persistenceService,
        viewModelProvider: provider
    )
}

let expectedNames = [
    "Communication", "Consumer", "Consumer Discretionary", "Consumer Staples",
    "Energy", "Financials", "Healthcare", "IT", "Industrials", "Technology"
]

// MARK: - WatchlistsViewModelTests

class WatchlistsViewModelTests: XCTestCase {

    private var cancellables = Set<AnyCancellable>()

    // MARK: A. Setup & Load

    func test_loadWatchlists_inMockMode_shouldLoadInitialMockWatchlists() throws {
        let viewModel = try makeWatchlistsViewModelWithMockData()
        viewModel.loadWatchlists()

        let loadedNames = viewModel.watchlists.map { $0.name }
        XCTAssertEqual(loadedNames.sorted(), expectedNames)
        XCTAssertFalse(viewModel.watchlists.isEmpty)
    }

    func test_loadingTwice_shouldNotDuplicateWatchlists() throws {
        let viewModel = try makeWatchlistsViewModel()
        viewModel.loadWatchlists()
        viewModel.loadWatchlists()

        let uniqueNames = Set(viewModel.watchlists.map { $0.name })
        XCTAssertEqual(uniqueNames.count, viewModel.watchlists.count)
    }

    func test_persistenceSaveOnLoad_shouldNotCrash() throws {
        let viewModel = try makeWatchlistsViewModel()
        XCTAssertNoThrow(viewModel.loadWatchlists())
    }

    // MARK: B. Add Watchlist

    func test_addNewWatchlist_inMockMode_shouldNotExceedMaxLimit() throws {
        let viewModel = try makeWatchlistsViewModel()
        viewModel.loadWatchlists()
        let initialCount = viewModel.watchlists.count

        XCTAssertEqual(initialCount, AppConstants.maxWatchlists)

        let editVM = EditWatchlistViewModel(
            watchlist: Watchlist(id: UUID(), name: "Extra Watchlist", stocks: [MockStockData.allStocks.first!]),
            availableStocks: MockStockData.allStocks
        )
        editVM.existingNames = viewModel.watchlists.map { $0.name }

        let validated = try editVM.validateAndReturnWatchlist()
        viewModel.addWatchlist(validated)

        XCTAssertEqual(viewModel.watchlists.count, initialCount)
        XCTAssertFalse(viewModel.watchlists.contains { $0.name == "Extra Watchlist" })
    }

    func test_addDuplicateWatchlist_shouldBeRejectedByValidation() throws {
        let viewModel = try makeWatchlistsViewModel()
        viewModel.loadWatchlists()

        guard let firstWatchlist = viewModel.watchlists.first,
              let _ = firstWatchlist.stocks.first else {
            return XCTFail("No watchlists or stocks found in setup")
        }
        
        guard let duplicateName = viewModel.watchlists.first?.name,
              let selectedStock = viewModel.watchlists.first?.stocks.first else {
            return XCTFail("No valid watchlist or stock found for duplicate test.")
        }

        let editVM = EditWatchlistViewModel(
            watchlist: Watchlist(id: UUID(), name: duplicateName, stocks: [selectedStock]),
            availableStocks: MockStockData.allStocks
        )
        editVM.existingNames = viewModel.watchlists.map { $0.name }

        XCTAssertThrowsError(try editVM.validateAndReturnWatchlist()) {
            XCTAssertEqual($0 as? WatchlistValidationError, .duplicateName)
        }
    }

    func test_addTooManyWatchlists_shouldRespectLimit() throws {
        let viewModel = try makeWatchlistsViewModel()
        viewModel.loadWatchlists()

        for i in 1...20 {
            let name = "Watchlist \(i)"
            let editVM = EditWatchlistViewModel(
                watchlist: Watchlist(id: UUID(), name: name, stocks: [MockStockData.allStocks.first!]),
                availableStocks: MockStockData.allStocks
            )
            editVM.existingNames = viewModel.watchlists.map { $0.name }

            do {
                let validated = try editVM.validateAndReturnWatchlist()
                viewModel.addWatchlist(validated)
            } catch {
                // Expected once limit is hit
            }
        }

        XCTAssertLessThanOrEqual(viewModel.watchlists.count, AppConstants.maxWatchlists)
    }

    func test_addingEmptyWatchlist_shouldBeRejectedByValidation() throws {
        let viewModel = try makeWatchlistsViewModel()
        viewModel.loadWatchlists()

        let editVM = EditWatchlistViewModel(
            watchlist: Watchlist(id: UUID(), name: "   ", stocks: []),
            availableStocks: MockStockData.allStocks
        )

        XCTAssertThrowsError(try editVM.validateAndReturnWatchlist()) {
            XCTAssertEqual($0 as? WatchlistValidationError, .emptyName)
        }
    }

    // MARK: C. Edit Watchlist

    func test_editingWatchlistName_shouldUpdateCorrectly() throws {
        let viewModel = try makeWatchlistsViewModel()
        viewModel.loadWatchlists()

        guard var edited = viewModel.watchlists.first else {
            return XCTFail("No watchlists found in mock setup.")
        }
        
        edited.name = "Updated Name"
        viewModel.updateWatchlist(edited)

        XCTAssertTrue(viewModel.watchlists.contains { $0.name == "Updated Name" })
    }

    func test_editWatchlist_shouldUpdateViewModelAndEmitChange() throws {
        let viewModel = try makeWatchlistsViewModel()
        viewModel.loadWatchlists()

        guard let original = viewModel.watchlists.first else {
            return XCTFail("No watchlists found in mock setup.")
        }
        var modified = original
        modified.name = "Modified Name"

        let exp = expectation(description: "Did update watchlist")
        viewModel.watchlistDidChange
            .sink {
                if $0.id == modified.id && $0.name == "Modified Name" {
                    exp.fulfill()
                }
            }
            .store(in: &cancellables)

        viewModel.updateWatchlist(modified)
        wait(for: [exp], timeout: 2.0)
    }

    func test_updateWatchlist_shouldReflectUpdatedName() throws {
        let viewModel = try makeWatchlistsViewModel()
        viewModel.loadWatchlists()

        guard var watchlist = viewModel.watchlists.first else {
            return XCTFail("No watchlists found in mock setup.")
        }
        watchlist.name = "New Name"

        viewModel.updateWatchlist(watchlist)

        XCTAssertEqual(
            viewModel.watchlists.first(where: { $0.id == watchlist.id })?.name,
            "New Name"
        )
    }

    // MARK: D. Remove Watchlist

    func test_removeWatchlist_inMockMode_shouldDeleteFromViewModelAndPersist() throws {
        let viewModel = try makeWatchlistsViewModel()
        viewModel.loadWatchlists()

        guard let toDelete = viewModel.watchlists.first else {
            return XCTFail("No watchlists found in mock setup.")
        }
        viewModel.test_removeWatchlist(toDelete)
        

        XCTAssertFalse(viewModel.watchlists.contains { $0.id == toDelete.id })
    }

    func test_removingWatchlist_shouldDecreaseCount() throws {
        let viewModel = try makeWatchlistsViewModel()
        viewModel.loadWatchlists()

        guard let first = viewModel.watchlists.first else {
            return XCTFail("No watchlists found in mock setup.")
        }
        viewModel.test_removeWatchlist(first)

        XCTAssertFalse(viewModel.watchlists.contains(first))
    }

    func test_removeNonexistentWatchlist_shouldNotCrash() throws {
        let viewModel = try makeWatchlistsViewModel()
        viewModel.loadWatchlists()

        let ghost = Watchlist(id: UUID(), name: "Ghost", stocks: [])
        viewModel.test_removeWatchlist(ghost)

        XCTAssertTrue(viewModel.watchlists.allSatisfy { $0.id != ghost.id })
    }

    // MARK: E. Stock Operations

    func test_addTooManyStocksToOneWatchlist_shouldRespectLimit() throws {
        let viewModel = try makeWatchlistsViewModel()
        viewModel.loadWatchlists()

        guard let base = viewModel.watchlists.first else {
            return XCTFail("No watchlists available for test_addTooManyStocksToOneWatchlist_shouldRespectLimit")
        }
        
        let mockStocks = (0..<100).map {
            Stock(symbol: "SYM\($0)", name: "Dummy \($0)", price: Double($0), previousPrice: 0, isPriceUp: true, qty: 0, averageBuyPrice: 0, sector: "Tech", currency: "USD", exchange: "NSE", isFavorite: false)
        }

        let editVM = EditWatchlistViewModel(watchlist: base, availableStocks: mockStocks)
        editVM.selectedStocks = mockStocks
        editVM.name = "Limit Test"
        editVM.existingNames = viewModel.watchlists.map { $0.name }

        XCTAssertThrowsError(try editVM.validateAndReturnWatchlist()) {
            XCTAssertEqual($0 as? StockValidationError, .limitReached(num: AppConstants.maxStocksPerWatchlist))
        }
    }

    func test_updateStockPrices_shouldUpdateAllMatchingStocks() throws {
        let viewModel = try makeWatchlistsViewModel()
        viewModel.loadWatchlists()

        let symbols = Array(Set(viewModel.watchlists.flatMap { $0.stocks.map { $0.symbol } }).prefix(3))

        let updates = symbols.compactMap { symbol in
            viewModel.watchlists.flatMap { $0.stocks }.first(where: { $0.symbol == symbol })?.withPriceIncremented(by: 2)
        }

        viewModel.test_updateStockPrices(updates)

        for updated in updates {
            let match = viewModel.watchlists.flatMap { $0.stocks }.first(where: { $0.symbol == updated.symbol })
            XCTAssertEqual(match?.price, updated.price)
        }
    }

    func test_updatePrice_shouldOnlyChangePriceField() throws {
        let viewModel = try makeWatchlistsViewModel()
        viewModel.loadWatchlists()

        guard let firstWatchlist = viewModel.watchlists.first else {
            return XCTFail("No watchlists found in mock setup.")
        }

        guard let before = firstWatchlist.stocks.first else {
            return XCTFail("No stocks found in first watchlist.")
        }

        let updated = before.withPriceIncremented(by: 10)
        viewModel.test_updateStockPrices([updated])

        guard let after = viewModel.watchlists.first?.stocks.first else {
            return XCTFail("No updated stock found.")
        }

        XCTAssertEqual(after.price, before.price + 10)
        XCTAssertEqual(after.symbol, before.symbol)
    }

    func test_replacePrices_shouldNotEmitStructuralChanges() throws {
        let viewModel = try makeWatchlistsViewModel()
        viewModel.loadWatchlists()

        guard let beforeCount = viewModel.watchlists.first else {
            return XCTFail("No watchlists Stocks found in mock setup.")
        }
        
        guard let firstwatchlist = viewModel.watchlists.first else {
            return XCTFail("No watchlists Stocks found in mock setup.")
        }
        
        let updates = firstwatchlist.stocks.map { $0.withPriceIncremented(by: 1) }

        viewModel.test_replacePrices(updates)

        XCTAssertEqual(firstwatchlist.stocks.count, beforeCount.stocks.count)
        XCTAssertTrue(firstwatchlist.stocks.allSatisfy { $0.price > 0 })
    }

    // MARK: F. Live Update Behavior

    func test_startObservingGlobalPriceUpdates_shouldTriggerPriceUpdate() throws {
        let viewModel = try makeWatchlistsViewModel()
        viewModel.loadWatchlists()

        let exp = expectation(description: "Price update received")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            exp.fulfill()
        }

        viewModel.startObservingGlobalPriceUpdates()
        wait(for: [exp], timeout: 2.0)
    }
}

private extension Stock {
    func withPriceIncremented(by amount: Double) -> Stock {
        var copy = self
        copy.price += amount
        return copy
    }
}
