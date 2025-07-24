//
//  RestStockRepositoryTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2025-07-23.
//

import Foundation
import XCTest
import Combine
@testable import iStocks

final class RestStockRepositoryTests: XCTestCase {
    
    var sut: RestStockRepositoryImpl!
    var mockRemote: MockRemoteDataSource!
    var mockPersistence: MockWatchlistPersistenceService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockRemote = MockRemoteDataSource()
        mockPersistence = MockWatchlistPersistenceService()
        sut = RestStockRepositoryImpl(service: mockRemote, persistenceService: mockPersistence)
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        sut = nil
        mockRemote = nil
        mockPersistence = nil
        super.tearDown()
    }

    func test_observeTop50Stocks_whenAllSymbolsPresent_shouldSkipAPI() {
        mockPersistence.savedStocks = NYSETop50Symbols.top50.toMockStocks(price: 100)

        let expectation = XCTestExpectation(description: "Should skip API and return saved")

        sut.observeTop50Stocks()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { stocks in
                      XCTAssertEqual(stocks.count, 50)
                      XCTAssertFalse(self.mockRemote.fetchCalled)
                      expectation.fulfill()
                  })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    func test_observeTop50Stocks_whenSomeMissing_shouldFetchFromAPI() {
        mockPersistence.savedStocks = [] // Force fetch

        let expectation = XCTestExpectation(description: "Should fetch from remote")

        sut.observeTop50Stocks()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { stocks in
                      XCTAssertEqual(stocks.count, NYSETop50Symbols.top50.count)
                      XCTAssertTrue(self.mockRemote.fetchCalled)
                      XCTAssertEqual(self.mockRemote.symbolsRequested.count, NYSETop50Symbols.top50.count)
                      expectation.fulfill()
                  })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    func test_fetchStockQuotes_shouldCallRemoteWithSymbols() {
        let expectation = XCTestExpectation(description: "Should call remote with symbols")
        let symbols = ["AAPL", "GOOGL"]

        sut.fetchStockQuotes(for: symbols)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { stocks in
                      XCTAssertTrue(self.mockRemote.fetchCalled)
                      XCTAssertEqual(self.mockRemote.symbolsRequested, symbols)
                      expectation.fulfill()
                  })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    func test_observeTop50Stocks_shouldEmitProgressUpdates() {
        let expectation = XCTestExpectation(description: "Should emit batch progress")

        var receivedProgress: BatchProgress?

        sut.progressPublisher
            .sink { progress in
                receivedProgress = progress
                if progress.current == 1 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        mockPersistence.savedStocks = [] // Force fetch
        _ = sut.observeTop50Stocks().sink(receiveCompletion: { _ in }, receiveValue: { _ in })

        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(receivedProgress?.current, 1)
        XCTAssertEqual(receivedProgress?.success, true)
    }
}
