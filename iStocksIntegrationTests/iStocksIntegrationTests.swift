//
//  iStocksIntegrationTests.swift
//  iStocksIntegrationTests
//
//  Created by Sakir Saiyed on 2025-07-23.
//

import XCTest
@testable import iStocks
internal import Combine

final class iStocksIntegrationTests: XCTestCase {

    // MARK: - Properties

    var sut: StockRemoteDataSource!
    var cancellables = Set<AnyCancellable>()

    // MARK: - Setup

    override func setUp() {
        let networkClient: NetworkClient = URLSessionNetworkClient()
        sut = StockRemoteDataSource(networkClient: networkClient, batchDelay: 1)
    }

    override func tearDown() {
        sut = nil
        cancellables.removeAll()
        super.tearDown()
    }
    
    // MARK: - Successful Fetch Tests

    func test_fetchRealtimePrices_forAAPL_shouldReturnPrice() {
        let expectation = self.expectation(description: "Fetch real-time price for AAPL")

        var receivedStocks: [Stock] = []

        sut.fetchRealtimePrices(for: ["AAPL"])
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Error occurred: \(error)")
                }
                expectation.fulfill()
            }, receiveValue: { stocks in
                receivedStocks = stocks
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 60)

        XCTAssertFalse(receivedStocks.isEmpty)
        XCTAssertEqual(receivedStocks.first?.symbol, "AAPL")
    }

    func test_fetchRealtimePrices_forAAPL_shouldReturnPriceUsingAsync() async throws {
        let stocks = try await sut.fetchRealtimePricesAsync(for: ["AAPL"])
        XCTAssertFalse(stocks.isEmpty)
        XCTAssertEqual(stocks.first?.symbol, "AAPL")
    }

    func test_fetchRealtimePrices_multipleSymbols_shouldReturnAllPrices() async throws {
        let symbols = ["AAPL", "GOOGL", "TSLA"]
        let stocks = try await sut.fetchRealtimePrices(for: symbols).asyncValues().first ?? []

        XCTAssertEqual(stocks.count, symbols.count)
        let returnedSymbols = stocks.map(\.symbol)
        XCTAssertTrue(Set(returnedSymbols).isSuperset(of: Set(symbols)))
    }

    func test_fetchRealtimePricesForTop5InBatches_shouldReturnAllStocks() async throws {
        let symbols = Array(NYSETop50Symbols.top50.prefix(1))
        print("Testing batch fetch for symbols:", symbols)
        var progressCalled = false

        let expectation = XCTestExpectation(description: "Wait for stock batch fetch")
        var receivedStocks: [Stock] = []

        let cancellable = sut.fetchRealtimePricesForTop50InBatches(
            symbols,
            batchSize: 1,
            onProgress: { index, total, _, _ in
                progressCalled = true
                print("Progress Batch: \(index)/\(total)")
            }
        )
        .sink(receiveCompletion: { completion in
            if case let .failure(error) = completion {
                XCTFail("Error: \(error)")
            }
        }, receiveValue: { stocks in
            print("[Received] \(stocks.count) stocks")
            receivedStocks.append(contentsOf: stocks)
            expectation.fulfill()
        })

        await fulfillment(of: [expectation], timeout: 120)

        XCTAssertEqual(receivedStocks.count, symbols.count)
        XCTAssertTrue(progressCalled)
        _ = cancellable // suppress warning
    }

    // MARK: - Error Handling Tests

    func test_fetchRealtimePrices_emptySymbols_shouldFailWithInvalidSymbolError() async {
        do {
            _ = try await sut.fetchRealtimePrices(for: []).asyncValues().first
            XCTFail("Expected failure for empty symbols, but succeeded.")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("symbol") || error.localizedDescription.contains("invalid"))
        }
    }
 
    func test_fetchRealtimePrices_duplicateSymbols_shouldReturnUniquePrices() async throws {
        let stocks = try await sut.fetchRealtimePrices(for: ["AAPL", "AAPL"]).asyncValues().first ?? []
        let uniqueSymbols = Set(stocks.map(\.symbol))
        XCTAssertEqual(uniqueSymbols.count, 1)
    }

    func test_fetchRealtimePrices_networkFailure_shouldMapToAppError() async {
        let failingClient = FailingNetworkClient()
        let sut = StockRemoteDataSource(networkClient: failingClient)

        do {
            _ = try await sut.fetchRealtimePrices(for: ["AAPL"]).asyncValues().first
            XCTFail("Expected error not thrown")
        } catch {
            XCTAssertTrue(error is AppError)
        }
    }
}
