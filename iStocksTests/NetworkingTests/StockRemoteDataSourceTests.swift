//
//  StockRemoteDataSourceTests.swift
//  iStocksTests
//
//  Created by Sakir Saiyed on 2026-03-21.
//

import XCTest
import Combine
@testable import iStocks

final class StockRemoteDataSourceTests: XCTestCase {

    private var mockClient: MockNetworkClient!
    private var sut: StockRemoteDataSource!
    private var cancellables: Set<AnyCancellable>!

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        cancellables = []
        mockClient = MockNetworkClient()
        sut = StockRemoteDataSource(networkClient: mockClient, batchDelay: 0)
    }

    override func tearDown() {
        sut = nil
        mockClient = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Creates a valid quote response JSON for given symbols (dictionary format)
    private func makeQuoteResponseJSON(symbols: [String]) -> Data {
        var dict: [String: Any] = [:]
        for symbol in symbols {
            dict[symbol] = [
                "symbol": symbol,
                "close": "150.00",
                "previousClose": "148.00",
                "status": "ok",
                "exchange": "NASDAQ",
                "currency": "USD"
            ]
        }
        return try! JSONSerialization.data(withJSONObject: dict)
    }

    /// Creates a single quote response JSON (single symbol format)
    private func makeSingleQuoteResponseJSON(symbol: String) -> Data {
        let obj: [String: Any] = [
            "symbol": symbol,
            "close": "150.00",
            "previousClose": "148.00",
            "status": "ok",
            "exchange": "NASDAQ",
            "currency": "USD"
        ]
        return try! JSONSerialization.data(withJSONObject: obj)
    }

    // MARK: - fetchRealtimePrices: Success (Dictionary Response)

    func test_fetchRealtimePrices_whenMultipleSymbols_shouldReturnStocks() {
        let symbols = ["AAPL", "MSFT"]
        mockClient.resultData = makeQuoteResponseJSON(symbols: symbols)

        let expectation = expectation(description: "Fetch realtime prices success")

        sut.fetchRealtimePrices(for: symbols)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, got error: \(error)")
                }
            }, receiveValue: { stocks in
                XCTAssertEqual(stocks.count, 2)
                let returnedSymbols = stocks.map { $0.symbol }
                XCTAssertTrue(returnedSymbols.contains("AAPL"))
                XCTAssertTrue(returnedSymbols.contains("MSFT"))
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - fetchRealtimePrices: Success (Single Response)

    func test_fetchRealtimePrices_whenSingleSymbol_shouldReturnStock() {
        let symbols = ["AAPL"]
        mockClient.resultData = makeSingleQuoteResponseJSON(symbol: "AAPL")

        let expectation = expectation(description: "Fetch single price success")

        sut.fetchRealtimePrices(for: symbols)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, got error: \(error)")
                }
            }, receiveValue: { stocks in
                XCTAssertEqual(stocks.count, 1)
                XCTAssertEqual(stocks.first?.symbol, "AAPL")
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - fetchRealtimePrices: Network Error Mapping

    func test_fetchRealtimePrices_whenNetworkError_shouldMapToAppError() {
        mockClient.resultError = NetworkError.unauthorized

        let expectation = expectation(description: "Network error mapped to AppError")

        sut.fetchRealtimePrices(for: ["AAPL"])
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    if let appError = error as? AppError,
                       case .network(let networkError) = appError,
                       case .unauthorized = networkError {
                        expectation.fulfill()
                    } else {
                        XCTFail("Expected AppError.network(.unauthorized), got \(error)")
                    }
                }
            }, receiveValue: { _ in
                XCTFail("Expected failure")
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - fetchRealtimePrices: TwelveDataAPIError Mapping

    func test_fetchRealtimePrices_whenTwelveDataAPIError_shouldMapToAppErrorAPI() {
        mockClient.resultError = TwelveDataAPIError.tooManyRequests

        let expectation = expectation(description: "API error mapped to AppError.api")

        sut.fetchRealtimePrices(for: ["AAPL"])
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    if let appError = error as? AppError,
                       case .api = appError {
                        expectation.fulfill()
                    } else {
                        XCTFail("Expected AppError.api, got \(error)")
                    }
                }
            }, receiveValue: { _ in
                XCTFail("Expected failure")
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - fetchRealtimePrices: Unknown Error Mapping

    func test_fetchRealtimePrices_whenUnknownError_shouldMapToAppErrorUnknown() {
        mockClient.resultError = NSError(domain: "test", code: 999, userInfo: nil)

        let expectation = expectation(description: "Unknown error mapped to AppError.unknown")

        sut.fetchRealtimePrices(for: ["AAPL"])
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    if let appError = error as? AppError,
                       case .unknown = appError {
                        expectation.fulfill()
                    } else {
                        XCTFail("Expected AppError.unknown, got \(error)")
                    }
                }
            }, receiveValue: { _ in
                XCTFail("Expected failure")
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - Endpoint Verification

    func test_fetchRealtimePrices_shouldCallNetworkClientWithCorrectEndpoint() {
        mockClient.resultData = makeQuoteResponseJSON(symbols: ["AAPL"])

        let expectation = expectation(description: "Endpoint verified")

        sut.fetchRealtimePrices(for: ["AAPL"])
            .sink(receiveCompletion: { _ in
                expectation.fulfill()
            }, receiveValue: { _ in })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)

        XCTAssertEqual(mockClient.requestCallCount, 1)
        XCTAssertEqual(mockClient.requestedEndpoints.first?.path, "/quote")
        XCTAssertEqual(mockClient.requestedEndpoints.first?.method, .get)
    }
}
