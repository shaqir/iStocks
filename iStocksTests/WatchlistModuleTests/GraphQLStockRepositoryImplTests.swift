//
//  GraphQLStockRepositoryImplTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed
//

import XCTest
import Combine
@testable import iStocks

final class GraphQLStockRepositoryImplTests: XCTestCase {

    private var mockGraphQL: MockStockGraphQLDataSource!
    private var mockPersistence: MockWatchlistPersistenceService!
    private var sut: GraphQLStockRepositoryImpl!
    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockGraphQL = MockStockGraphQLDataSource()
        mockPersistence = MockWatchlistPersistenceService()
        sut = GraphQLStockRepositoryImpl(dataSource: mockGraphQL, persistenceService: mockPersistence)
        cancellables = []
    }

    override func tearDown() {
        sut = nil
        mockGraphQL = nil
        mockPersistence = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - observeTop50Stocks

    func test_observeTop50Stocks_whenAllCached_shouldSkipGraphQL() {
        // All 50 symbols already in persistence — no need to hit GraphQL
        mockPersistence.savedStocks = NYSETop50Symbols.top50.map { Stock.mock(symbol: $0) }

        let expectation = expectation(description: "Should return cached stocks")

        sut.observeTop50Stocks()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { stocks in
                XCTAssertEqual(stocks.count, 50)
                XCTAssertFalse(self.mockGraphQL.fetchTop50Called, "Should NOT call GraphQL when all cached")
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    func test_observeTop50Stocks_whenMissing_shouldFetchViaGraphQL() {
        // Empty persistence — must fetch from GraphQL
        mockPersistence.savedStocks = []
        mockGraphQL.fetchTop50Result = .success([Stock.mock(symbol: "AAPL")])

        let expectation = expectation(description: "Should fetch via GraphQL")

        sut.observeTop50Stocks()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { stocks in
                XCTAssertTrue(self.mockGraphQL.fetchTop50Called, "Should call GraphQL for missing symbols")
                XCTAssertFalse(stocks.isEmpty)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    // MARK: - fetchStockQuotes

    func test_fetchStockQuotes_shouldDelegateToGraphQLDataSource() {
        let symbols = ["AAPL", "MSFT"]
        mockGraphQL.fetchQuotesResult = .success(symbols.map { Stock.mock(symbol: $0) })

        let expectation = expectation(description: "Should delegate to GraphQL")

        sut.fetchStockQuotes(for: symbols)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { stocks in
                XCTAssertTrue(self.mockGraphQL.fetchQuotesCalled)
                XCTAssertEqual(stocks.count, 2)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }

    // MARK: - Error Handling

    func test_observeTop50Stocks_whenGraphQLFails_shouldPropagateError() {
        mockPersistence.savedStocks = []
        mockGraphQL.fetchTop50Result = .failure(NetworkError.serverError(500))

        let expectation = expectation(description: "Should propagate error")

        sut.observeTop50Stocks()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    expectation.fulfill()
                }
            }, receiveValue: { _ in })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1)
    }
}
