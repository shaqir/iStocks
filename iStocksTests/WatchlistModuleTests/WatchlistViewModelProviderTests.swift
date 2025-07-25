//
//  WatchlistViewModelProviderTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2025-07-24.
//

import Foundation
import XCTest
@testable import iStocks
import Combine

final class WatchlistViewModelProviderTests: XCTestCase {
    
    var provider: DefaultWatchlistViewModelProvider!
    var mockWatchlist: Watchlist!
    var mockStocks: [Stock]!
    
    override func setUp() {
        super.setUp()
        let useCases = makeMockWatchlistUseCases()
        provider = DefaultWatchlistViewModelProvider(useCases: useCases)
        mockStocks = MockStockData.allStocks
        provider.allStocks = mockStocks
        mockWatchlist = Watchlist(id: UUID(), name: "Mock Watchlist", stocks: [mockStocks[0]])
    }
    
    func test_create_shouldReturnCorrectViewModel() {
        let viewModel = provider.viewModel(for: mockWatchlist)
        
        XCTAssertEqual(viewModel.watchlist.id, mockWatchlist.id)
        XCTAssertEqual(viewModel.watchlist.name, "Mock Watchlist")
        XCTAssertEqual(viewModel.watchlist.stocks.count, 1)
    }
    
    func test_multipleCreates_shouldReturnIndependentInstances() {
        let w1 = Watchlist(id: UUID(), name: "W1", stocks: [])
        let w2 = Watchlist(id: UUID(), name: "W2", stocks: [])
        
        let vm1 = provider.viewModel(for: w1)
        let vm2 = provider.viewModel(for: w2)
        
        XCTAssertNotEqual(vm1.watchlist.id, vm2.watchlist.id)
        XCTAssertEqual(provider.cachedViewModels.count, 2)
    }
    
    func makeMockWatchlistUseCases() -> WatchlistUseCases {
        WatchlistUseCases(
            observeMock: MockObserveMockStocksUseCase(),
            observeTop50: MockObserveTop50StocksUseCase(),
            observeLiveWebSocket: MockObserveStockPricesUseCase(),
            observeWatchlist: MockObserveWatchlistStocksUseCase(),
            fetchQuotesBySymbols: MockFetchStocksBySymbolUseCase()
        )
    }
}

//MARK: - Helper Mock Functions

final class MockObserveMockStocksUseCase: ObserveMockStocksUseCase {
    func execute() -> AnyPublisher<[iStocks.Stock], any Error> {
        Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func callAsFunction() -> AnyPublisher<[Stock], Error> {
        Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

final class MockObserveTop50StocksUseCase: ObserveTop50StocksUseCase {
    func execute() -> AnyPublisher<[iStocks.Stock], any Error> {
        Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func callAsFunction() -> AnyPublisher<[Stock], Error> {
        Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

final class MockObserveStockPricesUseCase: ObserveStockPricesUseCase {
    func execute() -> AnyPublisher<[iStocks.Stock], Never> {
        Just([])
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
    
    
    func subscribe(to symbols: [String]) {}
    
    
    
    func callAsFunction() -> AnyPublisher<[Stock], Error> {
        Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

final class MockObserveWatchlistStocksUseCase: ObserveWatchlistStocksUseCase {
    func execute(for watchlist: iStocks.Watchlist) -> AnyPublisher<[iStocks.Stock], Never> {
        Just([])
            .replaceError(with: [])
            .eraseToAnyPublisher()
    }
    
    func callAsFunction(_ watchlist: Watchlist) -> AnyPublisher<[Stock], Error> {
        Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}

final class MockFetchStocksBySymbolUseCase: FetchStocksBySymbolUseCase {
    func execute(for symbols: [String]) -> AnyPublisher<[iStocks.Stock], any Error> {
        Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
    
    func callAsFunction(_ symbols: [String]) -> AnyPublisher<[Stock], Error> {
        Just([]).setFailureType(to: Error.self).eraseToAnyPublisher()
    }
}
