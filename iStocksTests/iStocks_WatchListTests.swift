//
//  iStocksTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2025-06-07.
//

import Testing
@testable import iStocks
import SwiftData

@Suite
struct WatchlistTests {
    @Test
    func testMockStockServiceReturnsStocks() async throws {
        let mockService = MockStockService()
        let repo = StockRepositoryImpl(service: mockService)
        let useCase = FetchWatchlistStocksUseCaseImpl(repository: repo)

        let stocks = try await useCase.execute().asyncValue()
        #expect(stocks.count == 3)
        #expect(stocks.first?.symbol == "AAPL")
    }
}

@Suite
struct WatchlistPersistenceTests {

    @Test
    func testAddSymbolToWatchlist() throws {
        let container = try ModelContainer(for: WatchlistStock.self, configurations: .init(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let repo = SwiftDataWatchlistRepositoryImpl()
        let useCase = ManageWatchlistUseCaseImpl(repo: repo)

        useCase.add(symbol: "AAPL", in: context)

        let symbols = useCase.loadSymbols(from: context)
        #expect(symbols.contains("AAPL"))
    }
}

@Suite
struct WatchlistViewModelTests {
    @Test
    func testFetchStocksPopulatesData() async throws {
        let mockService = MockStockService()
        let repo = StockRepositoryImpl(service: mockService)
        let fetchUseCase = FetchWatchlistStocksUseCaseImpl(repository: repo)
        let manageUseCase = ManageWatchlistUseCaseImpl(repo: SwiftDataWatchlistRepositoryImpl())
        let viewModel = WatchlistViewModel(fetchUseCase: fetchUseCase, manageUseCase: manageUseCase)

        viewModel.fetchStocks()

        try await Task.sleep(nanoseconds: 500_000_000) // wait 0.5s
        #expect(viewModel.stocks.count == 3)
        #expect(viewModel.stocks.first?.symbol == "AAPL")
    }

    @Test
    func testSearchFiltering() async throws {
        let mockService = MockStockService()
        let repo = StockRepositoryImpl(service: mockService)
        let fetchUseCase = FetchWatchlistStocksUseCaseImpl(repository: repo)
        let manageUseCase = ManageWatchlistUseCaseImpl(repo: SwiftDataWatchlistRepositoryImpl())
        let viewModel = WatchlistViewModel(fetchUseCase: fetchUseCase, manageUseCase: manageUseCase)

        viewModel.fetchStocks()
        try await Task.sleep(nanoseconds: 500_000_000)
        viewModel.searchText = "TSLA"

        #expect(viewModel.filteredStocks.count == 1)
        #expect(viewModel.filteredStocks.first?.symbol == "TSLA")
    }
}

@Suite
struct WatchlistUseCaseTests {

    @Test
    func testFetchUseCaseReturnsMockData() async throws {
        let mockService = MockStockService()
        let repo = StockRepositoryImpl(service: mockService)
        let useCase = FetchWatchlistStocksUseCaseImpl(repository: repo)

        let stocks = try await useCase.execute().asyncValue()
        #expect(stocks.count == 3)
        #expect(stocks.first?.symbol == "AAPL")
    }

    @Test
    func testManageUseCaseAddAndLoad() throws {
        let container = try ModelContainer(for: WatchlistStock.self, configurations: .init(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let repo = SwiftDataWatchlistRepositoryImpl()
        let useCase = ManageWatchlistUseCaseImpl(repo: repo)

        useCase.add(symbol: "NFLX", in: context)
        let symbols = useCase.loadSymbols(from: context)

        #expect(symbols.contains("NFLX"))
    }

    @Test
    func testManageUseCaseDelete() throws {
        let container = try ModelContainer(for: WatchlistStock.self, configurations: .init(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let repo = SwiftDataWatchlistRepositoryImpl()
        let useCase = ManageWatchlistUseCaseImpl(repo: repo)

        useCase.add(symbol: "GOOG", in: context)
        useCase.remove(symbol: "GOOG", from: context)
        let symbols = useCase.loadSymbols(from: context)

        #expect(!symbols.contains("GOOG"))
    }
}
